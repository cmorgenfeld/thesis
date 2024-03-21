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
global dtadir "$dir\createddta"
global savedir "$dir\finaldta"
global logdir "$dir\log"
global graphdir "$dir\graph"
global tabledir "$dir\table"

* Set your directory
cd "${dir}"

* Start a log file, which is the text file that keeps all of the output from a Stata run
// log using "${logdir}\Thesis.log", replace


********************************
* Convert .txt files to .dta files
********************************
forvalues i = 2000/2020 {
	import delimited "${rawdir}\state_month_singleYear_15_49_allDeaths_`i'.txt", clear
	save "${dtadir}\state_month_singleYear_15_49_allDeaths_`i'", replace	
}


foreach name in "allDeaths" "intentionalSelfHarm" "transportDeaths" {
	forvalues i = 2000(5)2015 {
		local j = `i' + 4 + (`i' == 2015)
		
		import delimited "${rawdir}\state_year_singleYear_15_49_`name'_`i'_`j'.txt", clear
		save "${dtadir}\state_year_singleYear_15_49_`name'_`i'_`j'", replace	
	}
}

********************************
* Combine all the like .dta files (same death data)
********************************

use "${dtadir}\state_month_singleYear_15_49_allDeaths_2000", clear

forvalues i = 2001/2020 {
	append using "${dtadir}\state_month_singleYear_15_49_allDeaths_`i'"
}

save "${dtadir}\state_month_singleYear_15_49_allDeaths_2000_2020", replace

foreach name in "allDeaths" "intentionalSelfHarm" "transportDeaths" {
	use "${dtadir}\state_year_singleYear_15_49_`name'_2000_2004", clear
	
	forvalues i = 2005(5)2015 {
		local j = `i' + 4 + (`i' == 2015)
		
		append using "${dtadir}\state_year_singleYear_15_49_`name'_`i'_`j'"
	}
	
	save "${dtadir}\state_year_singleYear_15_49_`name'_2000_2020", replace
}

********************************
* Rename all the death variables
********************************

foreach name in "allDeaths" "intentionalSelfHarm" "transportDeaths" {
	use "${dtadir}\state_year_singleYear_15_49_`name'_2000_2020", clear
	
	rename deaths `name'
	drop notes
	drop if statecode == .
	
	save "${dtadir}\state_year_singleYear_15_49_`name'_2000_2020", replace
}

********************************
* Combine (& Clean) all the diiferent death data files (annual obs)
********************************

use "${dtadir}\state_year_singleYear_15_49_allDeaths_2000_2020", clear

foreach name in "intentionalSelfHarm" "transportDeaths" {
	merge 1:1 statecode singleyearagescode yearcode using "${dtadir}\state_year_singleYear_15_49_`name'_2000_2020", keepusing(`name')
	drop _merge
}

drop singleyearages yearcode cruderate
rename singleyearagescode age

save "${savedir}\state_year_singleYear_15_49_2000_2020", replace

********************************
* Clean Monthly Death Data
********************************

use "${dtadir}\state_month_singleYear_15_49_allDeaths_2000_2020", clear

rename deaths allDeaths
drop if statecode == .
drop notes singleyearages month cruderate population cruderate
rename singleyearagescode age
rename monthcode month

split month, p(/)
drop month 

rename month1 year
rename month2 month

destring year month, replace

merge m:1 statecode age year using "${savedir}\state_year_singleYear_15_49_2000_2020", keepusing(population)
drop _merge

drop if month == .

save "${savedir}\state_month_singleYear_15_49_allDeaths_2000_2020", replace


********************************
* Just 20-year olds
********************************
import delimited "${rawdir}\state_year_singleYear_20_allDeaths_2000_2020.txt", clear
save "${savedir}\state_year_singleYear_20_allDeaths", replace

import delimited "${rawdir}\state_year_fiveYear_15_49_allDeaths_2000_2020.txt", clear
save "${savedir}\state_year_fiveYear_15_49_allDeaths", replace


import delimited "${rawdir}\state_year_fiveYear_15_49_transportDeaths_2000_2020.txt", clear
save "${savedir}\state_year_fiveYear_15_49_transportDeaths", replace

import delimited "${rawdir}\state_year_fiveYear_15_49_intentionalSelfHarm_2000_2020.txt", clear
save "${savedir}\state_year_fiveYear_15_49_intentionalSelfHarm", replace

import delimited "${rawdir}\state_year_singleYear_20_transportDeaths_2000_2020.txt", clear
save "${savedir}\state_year_singleYear_20_transportDeaths", replace

import delimited "${rawdir}\state_year_singleYear_20_intentionalSelfHarm_2000_2020.txt", clear
save "${savedir}\state_year_fiveYear_singleYear_20_intentionalSelfHarm", replace


********************************
* Combine 5-year
********************************

foreach name in "allDeaths" "intentionalSelfHarm" "transportDeaths" {
	use "${savedir}\state_year_fiveYear_15_49_`name'", clear
	
	rename deaths `name'
	drop notes
	drop if statecode == .
	
	save "${savedir}\state_year_fiveYear_15_49_`name'", replace
}

use "${savedir}\state_year_fiveYear_15_49_allDeaths", clear

foreach name in "intentionalSelfHarm" "transportDeaths" {
	merge 1:1 statecode fiveyearagegroupscode yearcode using "${savedir}\state_year_fiveYear_15_49_`name'", keepusing(`name')
	drop _merge
}

drop fiveyearagegroups yearcode cruderate
rename fiveyearagegroupscode age

keep if age == "15-19" | age == "20-24" | age == "25-29"

gen ageGroup = (age == "20-24") + 2 * (age == "25-29")

save "${savedir}\state_year_fiveYear_15_29", replace

********************************
* Add 2021
********************************

foreach name in "allDeaths" "intentionalSelfHarm" "transportDeaths" {
	import delimited "${rawdir}\state_year_fiveYear_15_29_`name'_2021.txt", clear
	
	rename deaths `name'
	drop notes
	drop if statecode == .
	
	drop fiveyearagegroups yearcode cruderate
	rename fiveyearagegroupscode age
	
	gen ageGroup = (age == "20-24") + 2 * (age == "25-29")
	
	save "${savedir}\state_year_fiveYear_15_29_`name'_2021", replace
}

use "${savedir}\state_year_fiveYear_15_29", clear
// use "${savedir}\state_year_fiveYear_15_29_allDeaths_2021", clear


append using "${savedir}\state_year_fiveYear_15_29_allDeaths_2021"

foreach name in "intentionalSelfHarm" "transportDeaths" {
	merge 1:1 statecode ageGroup year using "${savedir}\state_year_fiveYear_15_29_`name'_2021", keepusing(`name')
	drop _merge
}

save "${savedir}\state_year_fiveYear_15_29", replace







	