#!/bin/bash

# dump and convert import and export quantities from SSP2
gdxdump ./output_data/results.gdx Symb=v24_shipment_quan | grep "'.L " | sed "s/'\.'/,/g" | sed "s/'.L /,/g" | sed "s/'//g" | sed "s/, //g" > ./output_data/shipmentquan.dat
gdxdump ./output_data/results.gdx Symb=v24_cap_tradeTransp | grep "'.L " | sed "s/'\.'/,/g" | sed "s/'.L /,/g" | sed "s/'//g" | sed "s/, //g" > ./output_data/cap_tradeTransp.dat
