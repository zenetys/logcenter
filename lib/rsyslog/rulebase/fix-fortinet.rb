version=2

##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

# <189>logver=604081234 timestamp=1694092511 devname="FW-FORTINET" devid="ABC12ABC1234A12A" ...
# <189>date=2023-09-01 time=22:51:48 devname="FW-FORTINET" devid="AB123ABC12345678" ...

rule=:<%-:number%>logver=%-:number%%-:rest%
rule=:<%-:number%>date=2%-:rest%
