import { useCallback, useState } from 'react';

import {
  httpPostEstimate
} from './requests';

function useEstimates (paste, cb) {
  const [isPendingEstimate, setPendingEstimate] = useState(false);

  const submitEstimate = async (e) => {
    e.preventDefault();
    setPendingEstimate(true);
    const response = await httpPostEstimate(paste);
    const success = response.ok !== false;
    setPendingEstimate(false);
    if (success) {
      cb(null, response);
    } else {
      cb(response);
    }
  }

  return {
    isPendingEstimate,
    submitEstimate
  };
}

export default useEstimates;