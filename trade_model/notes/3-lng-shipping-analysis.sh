#!/bin/bash
awk -F' ' '{numbRows+=1; s = $2/$3*1000; print $1 "\t\t" $2 "\t\t" $3 "\t\t" s; ; sum += s;} END {print sum/numbRows;}' 2-lng-shipping.dat
# see PDF file https://www.oxfordenergy.org/wpcms/wp-content/uploads/2018/02/The-LNG-Shipping-Forecast-costs-rebounding-outlook-uncertain-Insight-27.pdf
