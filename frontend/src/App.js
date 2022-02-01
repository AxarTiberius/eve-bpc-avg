import React from 'react';
import {AnimatorGeneralProvider} from '@arwes/animator';
import {BleepsProvider} from '@arwes/bleeps';
import {
  ArwesThemeProvider,
  Button,
  StylesBaseline,
  Text,
  TextField,
  FrameHexagon,
  FrameCorners
} from '@arwes/core';
import {
  globalStyles
} from './settings'

// End settings

const SOUND_ASSEMBLE_URL = '/assets/sounds/assemble.mp3';
const animatorGeneral = { duration: { enter: 1000, exit: 1000 } };
const audioSettings = { common: { volume: 0.25 } };
const playersSettings = { assemble: { src: [SOUND_ASSEMBLE_URL], loop: true } };
const bleepsSettings = { assemble: { player: 'assemble' } };

const App = () => {
  const [activate, setActivate] = React.useState(true);

  React.useEffect(() => {
    const timeout = 0
    return () => clearTimeout(timeout);
  }, [activate]);

  const submitInv = () => {
    console.log('submit inv')
    return false
  }

  return (
    <ArwesThemeProvider>
      <StylesBaseline styles={{
        'html': globalStyles.html,
        'body': globalStyles.body,
        '.arwes-text-field': { marginBottom: 20 },
        'form': {width: '750px', margin: '50px auto'},
        'textarea': {'maxHeight': '500px', 'height': '500px'}
      }} />
      <BleepsProvider
        audioSettings={audioSettings}
        playersSettings={playersSettings}
        bleepsSettings={bleepsSettings}
      >
        <AnimatorGeneralProvider animator={animatorGeneral}>
          <form onSubmit={event => { console.log(event); event.preventDefault(); return false} }>
            <FrameHexagon
              animator={{ activate }}
              hover
              inverted
            >
              <TextField
                multiline
                placeholder='Paste EVE inventory here'
                autoFocus
                defaultValue=''
                spellCheck={false}
                style={{
                  'width': '700px',
                  'minHeight': '500px'
                }}
              />
              <Button onClick={event => console.log(event)} FrameComponent={FrameCorners} style={{
                'margin': 'auto',
                'float': 'right'
              }}>
                <Text>Appraise Contracts</Text>
              </Button>
            </FrameHexagon>
          </form>
        </AnimatorGeneralProvider>
      </BleepsProvider>
    </ArwesThemeProvider>
  );
};


export default App
