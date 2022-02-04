import React from 'react';
import {AnimatorGeneralProvider} from '@arwes/animator';
import {BleepsProvider, useBleeps} from '@arwes/bleeps';
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
  globalStyles,
  audioSettings,
  playersSettings,
  bleepsSettings
} from './settings'

import useEstimates from './hooks/useEstimates'
import EstimateTable from './components/EstimateTable'

// End settings

const animatorGeneral = { duration: { enter: 1000, exit: 1000 } };

const Submit = ({ children }) => {
  const bleeps  = useBleeps();
  const onClick = () => bleeps.readout.play();
  return (
    <Button onClick={onClick} FrameComponent={FrameCorners} style={{
      'margin': 'auto',
      'float': 'right'
    }}>
      <Text>{children}</Text>
    </Button>
  );
}

const App = () => {
  const [activate, setActivate] = React.useState(true);

  const [paste, setPaste] = React.useState({})
  const [estimate, setEstimate] = React.useState({items: []})

  React.useEffect(() => {
    const timeout = 0
    return () => clearTimeout(timeout);
  }, [activate]);

  const onResponse = (err, response) => {
    if (err) {
      console.error('error', err)
      return;
    }
    setEstimate(response)
  }
  const {submitEstimate} = useEstimates(paste, onResponse)

  const onPasteChange = (e) => {
    setPaste({paste: e.target.value})
  }

  return (
    <ArwesThemeProvider>
      <StylesBaseline styles={{
        'html': globalStyles.html,
        'body': globalStyles.body,
        '.arwes-text-field': { marginBottom: 20 },
        'form': {width: '750px', margin: '50px auto'},
        'textarea': {'maxHeight': '500px', 'height': '500px'},
        '.hilite': {'color': '#F8F800'},
      }} />
      <BleepsProvider
        audioSettings={audioSettings}
        playersSettings={playersSettings}
        bleepsSettings={bleepsSettings}
      >
        <AnimatorGeneralProvider animator={animatorGeneral}>
          <form onSubmit={submitEstimate}>
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
                inputProps={{id: 'paste'}}
                onChange={onPasteChange}
                style={{
                  'width': '700px',
                  'minHeight': '500px'
                }}
              />
              <Submit>Appraise Contracts</Submit>
            </FrameHexagon>
          </form>
          <EstimateTable estimate={estimate} />
        </AnimatorGeneralProvider>
      </BleepsProvider>
    </ArwesThemeProvider>
  );
};

export default App
