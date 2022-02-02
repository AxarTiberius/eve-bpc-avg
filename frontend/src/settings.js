const FONT_FAMILY_ROOT = '"Titillium Web", sans-serif';
const IMAGE_URL = '/assets/images/wallpaper.jpg';
const SOUND_OBJECT_URL = '/assets/sounds/object.mp3';
const SOUND_ASSEMBLE_URL = '/assets/sounds/assemble.mp3';
const SOUND_TYPE_URL = '/assets/sounds/type.mp3';
const SOUND_CLICK_URL = '/assets/sounds/click.mp3';
const SOUND_ASK_URL = '/assets/sounds/ask.mp3';
const SOUND_ERROR_URL = '/assets/sounds/error.mp3';
const SOUND_INFO_URL = '/assets/sounds/information.mp3';
const SOUND_READOUT_URL = '/assets/sounds/readout.mp3';
const SOUND_TOGGLE_URL = '/assets/sounds/toggle.mp3';
const SOUND_WARNING_URL = '/assets/sounds/warning.mp3';

const globalStyles = {
  body: {
    fontFamily: FONT_FAMILY_ROOT,
    height: '100%'
  },
  html: {
    height: '100%',
    overflow: 'visible'
  }
};
const animatorGeneral = { duration: { enter: 200, exit: 200, stagger: 30 } };
const audioSettings = { common: { volume: 0.25 } };
const playersSettings = {
  object: { src: [SOUND_OBJECT_URL] },
  assemble: { src: [SOUND_ASSEMBLE_URL], loop: true },
  type: { src: [SOUND_TYPE_URL], loop: true },
  click: { src: [SOUND_CLICK_URL] },
  ask: { src: [SOUND_ASK_URL] },
  error: { src: [SOUND_ERROR_URL] },
  info: { src: [SOUND_INFO_URL] },
  readout: { src: [SOUND_READOUT_URL] },
  toggle: { src: [SOUND_TOGGLE_URL] },
  warning: { src: [SOUND_WARNING_URL] }
};
const bleepsSettings = {
  object: { player: 'object' },
  assemble: { player: 'assemble' },
  type: { player: 'type' },
  click: { player: 'click' },
  ask: { player: 'ask' },
  error: { player: 'error' },
  info: { player: 'info' },
  readout: { player: 'readout' },
  toggle: { player: 'toggle' },
  warning: { player: 'warning' }
};

export {
  animatorGeneral,
  globalStyles,
  IMAGE_URL,
  audioSettings,
  playersSettings,
  bleepsSettings,
};