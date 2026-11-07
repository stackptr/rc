# One ntfy event in, one chat.postMessage payload out (nothing for
# keepalives and empty messages). The title, or the message when there's
# no title, becomes the notification preview; priority 4+ goes to the
# alerts channel; the first tag is the emoji. Titles are plain text and
# get escaped; messages are Slack mrkdwn, so publishers can include links.
#
# The agents' topic is different: agents write text that other people can
# influence (logs, CI output, PR content), so their messages always go to
# the updates channel, whatever their priority, so they can't pass for a
# monitoring alert. They're also escaped like titles, so they can't carry
# links or mentions (<!channel>), always get the robot emoji, and say who
# sent them. The click link is dropped unless it's a plain https URL, for
# every topic, since a | or > in it would end Slack's <url|text> early.
def esc: gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;");
select((.event // "message") == "message" and (.message // "") != "")
| (.topic == $agentsTopic) as $agent
| ((.priority // 3) >= 4 and ($agent | not)) as $urgent
| (if $agent then .message | esc else .message end) as $message
| (.click // "" | if test("^https://[^\\s<>|]+$") then . else "" end) as $click
| (if $agent then "robot_face" else (.tags // [])[0] end) as $emoji
| (if $agent then "Agent: " else "" end) as $from
| (
    (if .title then [{type: "section", text: {type: "mrkdwn", text: $message}}] else [] end)
    + (if $click != "" then [{type: "context", elements: [{type: "mrkdwn", text: "<\($click)|Open>"}]}] else [] end)
    + (if $agent then [{type: "context", elements: [{type: "mrkdwn", text: "Posted by an agent on glyph"}]}] else [] end)
  ) as $blocks
| {
    channel: (if $urgent then $alerts else $updates end),
    text: ([$emoji | select(.) | ":\(.):"] + [$from + if .title then .title | esc else $message end] | join(" ")),
    unfurl_links: false,
    unfurl_media: false
  }
+ if $blocks == [] then {} else {attachments: [{color: (if $urgent then "#CC0000" else "#439FE0" end), blocks: $blocks}]} end
