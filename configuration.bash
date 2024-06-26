#!/usr/bin/bash

# from installation
export AMPLIFIER_SOUNDCARD=sndrpijustboomd
export AUDIO_FORMAT=S24_LE
export AUDIO_CHANNEL_NB=2
export AUDIO_RATE=192000

# ALSA loopback channels
export SNAPSERVER_LOOPBACK_SUBDEVICE='0'
export ALSA_LOOPBACK_CAPTURE_DEVICE='Loopback,0'
export ALSA_LOOPBACK_PLAYBACK_DEVICE='Loopback,1'
