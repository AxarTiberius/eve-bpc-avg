import React from 'react';
import {AnimatorGeneralProvider} from '@arwes/animator';
import {BleepsProvider} from '@arwes/bleeps';
import {
  ArwesThemeProvider,
  Button,
  Card,
  StylesBaseline,
  Text,
  TextField,
  FrameHexagon
} from '@arwes/core';
import {
  globalStyles
} from './settings'

// End settings

const SOUND_ASSEMBLE_URL = '/assets/sounds/assemble.mp3';
const animatorGeneral = { duration: { enter: 2000, exit: 2000 } };
const audioSettings = { common: { volume: 0.25 } };
const playersSettings = { assemble: { src: [SOUND_ASSEMBLE_URL], loop: true } };
const bleepsSettings = { assemble: { player: 'assemble' } };

const App = () => {
  const [activate, setActivate] = React.useState(true);

  React.useEffect(() => {
    const timeout = setTimeout(() => setActivate(!activate), 20000);
    return () => clearTimeout(timeout);
  }, [activate]);

  return (
    <ArwesThemeProvider>
      <BleepsProvider
        audioSettings={audioSettings}
        playersSettings={playersSettings}
        bleepsSettings={bleepsSettings}
      >
        <StylesBaseline />
        <AnimatorGeneralProvider animator={animatorGeneral}>
          <FrameHexagon
            animator={{ activate }}
            inverted
            hover
          >
            <div style={{ width: 600, height: 600 }} />
          </FrameHexagon>
        </AnimatorGeneralProvider>
      </BleepsProvider>
    </ArwesThemeProvider>
  );
};


export default App
