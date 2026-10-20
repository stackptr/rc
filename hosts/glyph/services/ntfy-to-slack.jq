# One ntfy event in, one chat.postMessage payload out (nothing for
# keepalives and empty messages). The title, or the message when there's
# no title, becomes the notification preview; priority 4+ goes to the
# alerts channel; the first tag is the emoji. Titles are plain text and
# get escaped; messages are Slack mrkdwn, so publishers can include links.
def esc: gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;");
select((.event // "message") == "message" and (.message // "") != "")
| ((.priority // 3) >= 4) as $urgent
| (
    (if .title then [{type: "section", text: {type: "mrkdwn", text: .message}}] else [] end)
    + (if .click then [{type: "context", elements: [{type: "mrkdwn", text: "<\(.click)|Open>"}]}] else [] end)
  ) as $blocks
| {
    channel: (if $urgent then $alerts else $updates end),
    text: ([(.tags // [])[0] | select(.) | ":\(.):"] + [if .title then .title | esc else .message end] | join(" ")),
    unfurl_links: false,
    unfurl_media: false
  }
+ if $blocks == [] then {} else {attachments: [{color: (if $urgent then "#CC0000" else "#439FE0" end), blocks: $blocks}]} end
