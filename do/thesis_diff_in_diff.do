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
// log using "${logdir}\Thesis.log", replace


*** This next line loads the data from your .dta file
use "${savedir}\state_year_singleYear_15_49_2000_2020", clear

gen age_group = (age >= 21) + (age >= 30) + (age >= 40)

global DEATH_TYPES allDeaths intentionalSelfHarm transportDeaths

collapse (mean) statecode (sum) $DEATH_TYPES (sum) population, by(state year age_group)

merge m:1 statecode using ${savedir}\legalization, keepusing(y_e y_l)

drop if y_e == .
drop _merge

gen post_effective = year > y_e
gen post_licensed = year > y_l

foreach death in $DEATH_TYPES {
	gen `death'_rate = `death' / (population / 100000)
	
	replace `death'_rate = -1 if `death'_rate == 0
		
	gen log_`death'_rate = log(`death'_rate)
}
	

global OPTIONS effective licensed
global AGE_GROUP 0 1 2 3 // 0 (15-20); 1 (21-29); 2 (30-39); 3 (40-49)

// keep if age == 21

label var log_allDeaths_rate "Log All Deaths"
label var log_intentionalSelfHarm_rate "Log Intentional Self Harm Deaths"
label var log_transportDeaths_rate "Log Transport Deaths"

local type_name = "Legalization of Recreational Marijuana Use"

foreach t in $OPTIONS {
	foreach group in $AGE_GROUP {
		est clear
		preserve 
		
		keep if age_group == `group'
		
		local lower_age = 15 * (`group' == 0) + 21 * (`group' == 1) + 30 * (`group' == 2) + 40 * (`group' == 3)
		local upper_age = 20 * (`group' == 0) + 29 * (`group' == 1) + 39 * (`group' == 2) + 49 * (`group' == 3)
			
		foreach death in $DEATH_TYPES {
			eststo: reghdfe log_`death'_rate post_`t', absorb(statecode year)
		}
		esttab using "${tabledir}\diff_in_diff_`t'_`group'.tex", replace title("`type_name' on Death Rate for `lower_age'- to `upper_age'-Year-Olds") label
		
		restore
	}
	local type_name = "Licensed Sale of Recreational Marijuana"
}

esttab, label
