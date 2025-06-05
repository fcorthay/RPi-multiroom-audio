#!/usr/bin/bash

# scripts base directory
export AUDIO_BASE_DIR=$(dirname "${BASH_SOURCE[0]}")

# multiroom environment
export MULTIROOM_SNAPCAST_SERVER='Persephone.local'

# from installation
export AMPLIFIER_SOUNDCARD=sndrpijustboomd
export AUDIO_BIT_NB=32
export AUDIO_CHANNEL_NB=2
export AUDIO_RATE=192000

# ALSA loopback channels
export CAMILLADSP_LOOPBACK_SUBDEVICE='0'
export SNAPSERVER_LOOPBACK_SUBDEVICE='1'
export ALSA_LOOPBACK_CAPTURE_DEVICE='Loopback,0'
export ALSA_LOOPBACK_PLAYBACK_DEVICE='Loopback,1'

# CamillaDSP
export CAMILLA_DIR=`realpath -s $AUDIO_BASE_DIR/CamillaDSP/`
export CAMILLA_CONFIGURATION_DIR="$CAMILLA_DIR/Configuration"
export CAMILLA_CONFIGURATION_FILE="$CAMILLA_CONFIGURATION_DIR/camillaconfig.yaml"
export CAMILLA_CONFIGURATIONS_DIR="$CAMILLA_CONFIGURATION_DIR/Configurations"
export CAMILLA_COEFFICIENTS_DIR="$CAMILLA_CONFIGURATION_DIR/Coefficients"
export CAMILLA_BACKEND_DIR="$CAMILLA_DIR/Backend"
export CAMILLA_CONTROL_PORT='5005'
export CAMILLA_GUI_PORT='5006'
export CAMILLA_GUI_STATE_FILE="$CAMILLA_BACKEND_DIR/statefile.yml"
