import React from 'react'
import {Table} from '@arwes/core'

// TODO: Update this to use new estimate fields
const headers = [
  { id: 'typeID', data: 'typeID' },
  { id: 'typeName', data: 'Name' },
  { id: 'minSoloPrice_human', data: 'Solo' },
  { id: 'minPackagePrice_human', data: 'Package' },
  { id: 'minMarketPrice_human', data: 'Market' },
  { id: 'marketLiquidity_human', data: 'Liquidity' },
  { id: 'minPrice_human', data: 'Lowest Price' },
  { id: 'itemsFound', data: 'Your Quantity' },
  { id: 'totalMarketValue_human', data: 'Your Value' },
  { id: 'marketType', data: 'Method' },
  { id: 'minPriceRegionName', data: 'Region' }
];
const columnWidths = ['6%', '40%', '6%', '6%', '6%', '6%', '6%', '6%', '6%', '6%', '6%'];

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
      <div>
        <center>
          <h3>Your Total Value:</h3>
          <h1 class="hilite">{ props.estimate.totalMarketValue_human } ISK</h1>
        </center>
        <Table
          animator={{ activate }}
          headers={headers}
          dataset={dataset}
          columnWidths={columnWidths}
        />
      </div>
    );
  }
  else {
    return '';
  }
};

export default EstimateItems
