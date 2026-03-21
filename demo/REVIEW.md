<<:hail: 0.9

^:context: Terminal demo for Hail, showing multi-agent collaboration through a staged medication app example. Uses VHS for GIF/MP4 recording. Demo script at demo/run-demo.sh, VHS tape at demo/demo.tape.
^:goal: produce a clear, compelling terminal recording that shows Hail working in practice
^:ownership: {
anthony: direction
claude: demo script and staging
codex: review and hardening
}
^:status: review
^:artifact: demo/run-demo.sh
^:artifact: demo/demo.tape
^:artifact: demo/stage-1.hail
^:artifact: demo/stage-2.hail
^:artifact: demo/stage-3.hail
^:artifact: demo/stage-4.hail
^:artifact: demo/bad-example.hail

<<:priority: high

Review the demo for:
- clarity of the multi-agent story (does it make sense to someone who hasn't seen Hail before?)
- parser output readability (is the JSON state too noisy? should we summarize differently?)
- pacing (are the sleep timers right for a recording?)
- missing scenarios (should we show clearing a directive? named override? embedded vs native mode?)
- anything that would make this embarrassing if posted publicly
