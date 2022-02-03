import React from 'react'
import {Table} from '@arwes/core'

// TODO: Update this to use new estimate fields
const headers = [
  { id: 'typeID', data: 'typeID' },
  { id: 'typeName', data: 'Name' },
  { id: 'soloContracts', data: '# Solo' },
  { id: 'packageContracts', data: '# Package' },
  { id: 'minSoloPrice_human', data: 'Min. Solo' },
  { id: 'minPackagePrice_human', data: 'Min. Package' },
  { id: 'minPrice_human', data: 'Market Value' },
  { id: 'itemsFound', data: 'Items Found' },
  { id: 'totalMarketValue_human', data: 'Total Market Value' },
  { id: 'minPriceRegionName', data: 'Region' }
];
const columnWidths = ['6%', '46%', '6%', '6%', '6%', '6%', '6%', '6%', '6%', '6%'];

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
          data: item[field.id] === null ? '' : String(item[field.id])
        }
      })
    }
  });

  if (props.estimate.items.length) {
    return (
      <Table
        animator={{ activate }}
        headers={headers}
        dataset={dataset}
        columnWidths={columnWidths}
      />
    );
  }
  else {
    return '';
  }
};

export default EstimateItems
