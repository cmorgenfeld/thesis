*******************************************************************
* Name: Creighton Morgenfeld          						            
* Date: 
* Purpose: this program serves as a base shell for all stata do files 
*******************************************************************

*** This next line is the path to this .do file, you can cut and paste this path into stata to run the .do file
* do C:\Users\Creighton.Morgenfeld\Documents\AY23-2\SS489C\do\ss489c-replication2.do

********************************
* Standard Stata Configuration
********************************
clear all
set more off
cap log close

set scheme sj

global dir "C:\Users\Creighton\Documents\Stata\Thesis"  // copy actual file path inside the quotes on this line

global dodir "$dir\do"
global rawdir "$dir\raw"
global savedir "$dir\finaldta"
global logdir "$dir\log"
global graphdir "$dir\graph"
global tabledir "$dir\table"

* Set your directory
cd "${dir}"

* Start a log file, which is the text file that keeps all of the output from a Stata run
log using "${logdir}\Thesis.log", replace


*** This next line loads the data from your .dta file
use "${savedir}\missing_values", clear

estpost tabstat allDeaths transportDeaths intentionalSelfHarm, by(state) nototal

estout, cells("allDeaths transportDeaths intentionalSelfHarm") label collabels("All Deaths" "Transport Deaths" "Intentional Self-Harm Deaths")

esttab using "$tabledir\missing_values.tex", replace cells("allDeaths transportDeaths intentionalSelfHarm") label collabels("All Deaths" "Transport Deaths" "Intentional Self-Harm Deaths") noobs


esttab using "$tabledir\missing_values.tex", replace 


* 20-year-olds
use "${savedir}\state_year_singleYear_20_allDeaths", clear
drop notes
drop if statecode == .

collapse (count) deaths, by(state)

replace deaths = 21 - deaths
	
tabstat deaths, by(state) nototal

drop if deaths == 0

tabstat deaths, by(state) nototal
drop if state == "Delware"

* Five year groups

use "${savedir}\state_year_fiveYear_15_49_allDeaths", clear
drop notes
drop if statecode == .

collapse (count) deaths, by(state)

replace deaths = 21 - deaths
	
tabstat deaths, by(state) nototal

drop if deaths == 0

tabstat deaths, by(state) nototal
drop if state == "Delware"

* Five year groups

use "${savedir}\state_year_fiveYear_15_49_intentionalSelfHarm", clear
drop notes
drop if statecode == .

collapse (count) deaths, by(state)

replace deaths = 147 - deaths
drop if deaths == 0
	
tabstat deaths, by(state) nototal

* 20-year-olds
use "${savedir}\state_year_singleYear_20_intentionalSelfHarm", clear
drop notes
drop if statecode == .

collapse (count) deaths, by(state)

replace deaths = 21 - deaths
drop if deaths == 0
	
tabstat deaths, by(state) nototal



* 20-year-olds
use "${savedir}\state_year_singleYear_20_allDeaths", clear
drop notes
drop if statecode == .

collapse (count) deaths, by(state)

replace deaths = 21 - deaths
	
tabstat deaths, by(state) nototal

drop if deaths == 0


