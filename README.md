# Auto Broadcast Generator
Generate audio broadcast automatically from a list of events using ChatGPT and ElevenLabs.

## Overview
There are so many ways to consume information these days. Our daily routines necessitate being informed.

This application was developed out of 1) a desire to consolidate daily notification information and 2) a love of radio broadcasts.

My home cameras send me notifications all the time. My home thermostat is reporting all manner of information. I get lots of packages and emails relating to their current status. And I always want to know what the weather is up to.

This app collects information from all of those sources and creates a list of events.
It then asks [ChatGPT](https://openai.com/blog/chatgpt) to develop a script that a radio broadcaster might use.
It then asks [ElevenLabs](https://elevenlabs.io/) to generate an audio file of someone reading that script.
It then uses the `sox` library to mix in some intro/outro music.

Viola! You get something like this:

https://github.com/Fishy49/auto-broadcast-generator/assets/5632528/9242c7cb-7e00-4a3a-8cce-632f6ccb0fb7

You can then use your own cleverness to upload this to a playlist or maybe even look at [PiFmRds](https://github.com/ChristopheJacquet/PiFmRds) for some ideas!

## Current State and Future
The current state as of writing is 0.1 - I have this working personally for me but to make this accessible and easy to implement for others will require a lot of work.

The integration with the Google Smart Home stuff is insanely involved (and for me, running in sandbox mode).

Long Term, I plan on accomplishing the following things:

-[ ] Separate the Event Collectors into "plugins" that can be easily enable and disabled. This will make it easy to write additional even sources later.
-[ ] Update the UI to make it easier to manage your plugins and sensitive data like API keys, etc.
-[ ] Add a commercials feature that, with some options for prompting, can have [ChatGPT](https://openai.com/blog/chatgpt) and [ElevenLabs](https://elevenlabs.io/) generate commercials or other content. The goal being you can string this files together to eventually create your own station full of content
-[ ] Testing - since this is currently a develop-by-the-seat-of-my-pants operation without a clear spec, testing doesn't exist but I'd want this to change as the features solidify more.
-[ ] Add support for more DB engines - currently this was designed for a Raspberry Pi 4 and uses SQLite.
-[ ] Use something more robust than `Thread` - don't get me wrong the simplicity of this is great and it hasn't given me any trouble but I'm not going to pretend I know what I'm doing with Threads - it'd be good to implement a better-developed job queue engine of some sort.
