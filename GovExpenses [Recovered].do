* Importing population data first from 2022 
import excel "C:\Users\bchen\Downloads\NST-EST2022-CHG.xlsx", sheet("NST-EST2022-CHG") cellrange(E11:E61) clear

drop in 9 
save "StatePopulation.dta", replace

* Import 2022 State Total Expenditure 
import excel "C:\Users\bchen\Downloads\2022 ASFIN State Totals.xlsx", sheet("2022 ASFIN") clear

drop in 1/4
gen row_num = _n 
rename A var_label 
list var_label row_num 

keep if row_num == 1 | row_num == 7 | row_num == 31 | row_num == 32 | row_num == 46 | row_num == 62 | row_num == 63 | row_num == 65 

list var_label row_num in 1/8 
drop var_label row_num 

export delimited using "rename.csv", replace novarnames 
import delimited using "rename.csv", varnames(1) clear


foreach var of varlist alaska florida nevada southdakota texas washington wyoming {
    replace `var' = "" if `var' == "X"
    destring `var', replace
}

describe 
list in 1/5
xpose, clear varname 
rename _varname State 
order State 
drop if State == "unitedstates" 

merge 1:1 _n using "StatePopulation.dta"
keep if _merge == 3 
drop _merge 
describe 

* Data Organizing 
rename v1 TotalTaxes 
rename v2 IndividualIncomeTaxes
rename v3 CorporationIncomeTaxes
rename v4 TotalExpenditure 
rename v5 PublicWelfare
rename v6 Education 
rename v7 Health 
rename E Population

gen Party = ""

replace Party = "Democratic" if inlist(State,"california","colorado","connecticut","delaware","hawaii","illinois","maine","maryland")
replace Party = "Democratic" if inlist(State,"massachusetts","michigan","minnesota","nevada","newhampshire","newjersey","newmexico")
replace Party = "Democratic" if inlist(State,"newyork","oregon","rhodeisland","vermont","virginia","washington","wisconsin")

replace Party = "Republican" if inlist(State,"alabama","alaska","arizona","arkansas","florida","georgia","idaho","indiana")
replace Party = "Republican" if inlist(State,"iowa","kansas","kentucky","louisiana","mississippi","missouri","montana")
replace Party = "Republican" if inlist(State,"nebraska","northcarolina","northdakota","ohio","oklahoma","pennsylvania")
replace Party = "Republican" if inlist(State,"southcarolina","southdakota","tennessee","texas","utah","westvirginia","wyoming")

format TotalTaxes IndividualIncomeTaxes CorporationIncomeTaxes TotalExpenditure PublicWelfare Education Health Population %15.0fc

list State TotalExpenditure TotalTaxes PublicWelfare Education Health Population in 1/5

* Data Analysis of Party affiliation per state 
tab Party 
gen dem = (Party == "Democratic")
label define dem 0 "Republican" 1 "Democratic"
label val dem dem 

corr PublicWelfare TotalExpenditure if dem == 1
corr PublicWelfare TotalExpenditure if dem == 0 

corr Education TotalExpenditure if dem == 1
corr Education TotalExpenditure if dem == 0 

corr Health TotalExpenditure if dem == 1
corr Health TotalExpenditure if dem == 0 

* Data analysis of national government 
corr PublicWelfare TotalExpenditure 
reg PublicWelfare TotalExpenditure
*coefficient total effect 

display "Slope (thousands per thousand) = " _b[TotalExpenditure]
display "That means for each $1000 in total expenditure, states spend about $" (1000 * _b[TotalExpenditure]) " on public welfare."

gen pct_welfare = (PublicWelfare / TotalExpenditure) * 100 
gen pct_education = (Education / TotalExpenditure) * 100 
gen pct_health = (Health / TotalExpenditure) * 100 
sum pct_welfare pct_education pct_health
list State pct_welfare pct_education pct_health

gen welfare_pc = PublicWelfare / Population
gen tax_pc = TotalTaxes / Population
gen expenditure_pc = TotalExpenditure / Population
list State welfare_pc tax_pc expenditure_pc 
reg welfare_pc expenditure_pc tax_pc 

reg PublicWelfare TotalExpenditure dem
reg PublicWelfare TotalExpenditure Population 
*population = antecendent effect
*total = direct effect 

reg Population TotalEx 
* multiply population coefficient 
* no spirous effect

reg PublicWelfare TotalExpenditure
esttab 

reg PublicWelfare TotalExpenditure
outreg2 using result, dec(2) excel level(95)
reg PublicWelfare TotalExpenditure Population
outreg2 using result, dec(2) excel level(95) append
