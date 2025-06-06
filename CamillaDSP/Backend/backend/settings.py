import os
import pathlib
import sys

import yaml
from yaml.scanner import ScannerError
from jsonschema import Draft202012Validator

import logging

from .settings_schemas import GUI_CONFIG_SCHEMA, BACKEND_CONFIG_SCHEMA

BASEPATH = pathlib.Path(__file__).parent.parent.absolute()
CONFIG_PATH = BASEPATH / "config" / "camillagui.yml"
GUI_CONFIG_PATH = BASEPATH / "config" / "gui-config.yml"

# Default values for the optional gui config.
GUI_CONFIG_DEFAULTS = {
    "hide_capture_samplerate": False,
    "hide_silence": False,
    "hide_capture_device": False,
    "hide_playback_device": False,
    "hide_multithreading": False,
    "apply_config_automatically": False,
    "save_config_automatically": False,
    "status_update_interval": 100,
    "volume_range": 50,
    "volume_max": 0,
}

# Default values for the optional settings.
BACKEND_CONFIG_DEFAULTS = {
    "default_config": None,
    "statefile_path": None,
    "on_set_active_config": None,
    "on_get_active_config": None,
    "supported_capture_types": None,
    "supported_playback_types": None,
    "log_file": None,
}


def _load_yaml(path):
    """
    Load a yaml file into a dict.
    Logs the error and returns None if the file can't be read.
    """
    try:
        with open(path) as f:
            config = yaml.safe_load(f)
            return config
    except ScannerError as e:
        logging.error(f"Invalid yaml syntax in config file: {path}")
        logging.error(f"Details: {e}")
    except OSError as e:
        logging.error(f"Config file could not be opened: {path}")
        logging.error(f"Details: {e}")
    return None


def _read_and_validate_file(path, schema):
    config = _load_yaml(path)
    if config is None:
        return None
    validator = Draft202012Validator(schema)
    errors = list(validator.iter_errors(config))
    if len(errors) > 0:
        logging.error(f"Error in config file '{path}'")
        for e in errors:
            logging.error(f"Parameter '{'/'.join([str(p) for p in e.path])}': {e.message}")
        return None
    return config

def get_config(path):
    """
    Get backend config.
    Exits if the config can't be read.
    """
    config = _read_and_validate_file(path, BACKEND_CONFIG_SCHEMA)
    if config is None:
        sys.exit()
    config["config_dir"] = os.path.abspath(os.path.expanduser(config["config_dir"]))
    config["coeff_dir"] = os.path.abspath(os.path.expanduser(config["coeff_dir"]))
    config["default_config"] = absolute_path_or_none_if_empty(config["default_config"])
    config["statefile_path"] = absolute_path_or_none_if_empty(config["statefile_path"])
    config["gui_config_file"] = absolute_path_or_none_if_empty(config["gui_config_file"])
    for key, value in BACKEND_CONFIG_DEFAULTS.items():
        if key not in config:
            config[key] = value
    logging.debug("Backend configuration:")
    logging.debug(yaml.dump(config))
    
    config["can_update_active_config"] = can_update_active_config(config)
    
    # Read the gui config.
    # This is only to validate the file and log any problems.
    # The result is not used.
    gui_config_path = config["gui_config_file"]
    if gui_config_path is None:
        gui_config_path = GUI_CONFIG_PATH
    get_gui_config_or_defaults(gui_config_path)

    return config


def can_update_active_config(config):
    """
    Check if the backend is able to persist the active config filename.
    """
    statefile_supported = False
    external_supported = False
    if config["statefile_path"]:
        statefile = config["statefile_path"]
        is_writable = is_file_writable(statefile)
        if is_writable:
            statefile_supported = True
        else:
            logging.error(f"The statefile {statefile} is not writable.")
    if config["on_set_active_config"] and config["on_get_active_config"]:
        logging.debug(
            "Both 'on_set_active_config' and 'on_get_active_config' options are set"
        )
        external_supported = True
    return statefile_supported or external_supported


def is_file_writable(path):
    """
    Check if a filename can be written to.
    If the file doesn't already exist it checks if it's possible
    to create a file in the parent directory.
    """
    exists = os.path.isfile(path)
    if exists:
        return _is_writable(path)
    else:
        parent = os.path.dirname(path)
        return _is_writable(parent)


def _is_writable(path):
    """
    Helper to check write permission on a symlink, file or dir.
    """
    if os.access in os.supports_follow_symlinks:
        return os.access(path, os.W_OK, follow_symlinks=False)
    else:
        return os.access(path, os.W_OK)


def absolute_path_or_none_if_empty(path):
    """
    Make a path absolute, of return None if the given path is empty.
    """
    if path:
        return os.path.abspath(os.path.expanduser(path))
    else:
        return None


def get_gui_config_or_defaults(path):
    """
    Get the gui config from file if it exists,
    if not return the defaults.
    """
    config = _read_and_validate_file(path, GUI_CONFIG_SCHEMA)
    if config is not None:
        for key, value in GUI_CONFIG_DEFAULTS.items():
            if key not in config:
                config[key] = value
        return config
    else:
        logging.warning("Unable to read gui config file, using defaults")
        return GUI_CONFIG_DEFAULTS

