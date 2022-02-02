import React from 'react'
import {Table} from '@arwes/core'

// TODO: Update this to use new estimate fields
const headers = [
  { id: 'typeID', data: 'typeID' },
  { id: 'name', data: 'Name' },
  { id: 'soloContracts', data: '# Solo' },
  { id: 'meanPrice_human', data: 'Price Avg.' }
];
const columnWidths = ['10%', '60%', '10%', '20%'];

const EstimateItems = (props) => {
  const [activate, setActivate] = React.useState(true);

  React.useEffect(() => {
    const timeout = 0;
    return () => clearTimeout(timeout);
  }, [activate]);

  const dataset = props.estimate.items.map(function (item) {
    return {
      id: 'item_' + item.typeID,
      columns: headers.map(function (field) {
        return {
          id: 'item_' + item.typeID + '_' + field.id,
          data: String(item[field.id])
        }
      })
    }
  });

  return (
    <Table
      animator={{ activate }}
      headers={headers}
      dataset={dataset}
      columnWidths={columnWidths}
    />
  );
};

export default EstimateItems
