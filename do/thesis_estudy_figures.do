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
use "${savedir}\state_year_singleYear_15_49_2000_2020", clear

gen age_group = (age >= 21) + (age >= 30) + (age >= 40)


global DEATH_TYPES allDeaths intentionalSelfHarm transportDeaths

collapse (mean) statecode (sum) $DEATH_TYPES (sum) population, by(state year age_group)

merge m:1 statecode using ${savedir}\legalization, keepusing(y_e y_l)

drop if y_e == .
drop _merge

gen years_post_effective = year - y_e
gen years_post_licensed = year - y_l


foreach death in $DEATH_TYPES {
	gen `death'_rate = `death' / (population / 100000)
	
	replace `death'_rate = -1 if `death'_rate == 0
	
	gen log_`death'_rate = log(`death'_rate)
}
	

global OPTIONS effective licensed
global AGE_GROUP 0 1 2 3 // 0 (15-20); 1 (21-29); 2 (30-39); 3 (40-49)


foreach t in $OPTIONS {
	global LEADS_`t'
	global LAGS_`t'



	forval year = 2/5 {
		gen lead_`year'_`t' = (years_post_`t' == -`year')
		
		global LEADS_`t' ${LEADS_`t'} lead_`year'_`t'
	}

	forval year = 0/4 {
		gen lag_`year'_`t' = (years_post_`t' == `year')
		
		global LAGS_`t' ${LAGS_`t'} lag_`year'_`t'
	}
}


// keep if age == 21



foreach t in $OPTIONS {
	foreach death in $DEATH_TYPES {
		sum years_post_`t'
		reghdfe log_`death'_rate ${LEADS_`t'} ${LAGS_`t'}, absorb(statecode year)
	}
}


local x_axis_name = "Years Relative to Legalization of Recreational Marijuana Use"

foreach t in $OPTIONS {
	foreach group in $AGE_GROUP {
		preserve
		
			keep if age_group == `group'
			
			local lower_age = 15 * (`group' == 0) + 21 * (`group' == 1) + 30 * (`group' == 2) + 40 * (`group' == 3)
			local upper_age = 20 * (`group' == 0) + 29 * (`group' == 1) + 39 * (`group' == 2) + 49 * (`group' == 3)
			
			
			reghdfe log_allDeaths_rate ${LEADS_`t'} ${LAGS_`t'}, absorb(statecode year)
		

			gen coef_`t' = .
			gen se_`t' = .

			local i = -5
			foreach q in ${LEADS_`t'} {
				replace coef_`t' = _b[`q'] if years_post_`t' == `i'
				replace se_`t' = _se[`q'] if years_post_`t' == `i'
				
				local i = `i' + 1
			}

				replace coef_`t' = 0 if years_post_`t' == -1
				replace se_`t' = 0 if years_post_`t' == -1

			local j = 0
			local i = 0
			foreach q in ${LAGS_`t'} {
				replace coef_`t' = _b[`q'] if years_post_`t' == `i'
				replace se_`t' = _se[`q'] if years_post_`t' == `i'
				
				local i = `i' + 1
			}

			gen lb_`t' = coef_`t' - 1.96*se_`t'
			gen ub_`t' = coef_`t' + 1.96*se_`t'
			
			drop if years_post_`t' < -5 | years_post_`t' > 4
			


			twoway rcap lb_`t' ub_`t' years_post_`t', color(gs11) sort || ///
				line coef_`t' years_post_`t', connect(L) lcolor(black) lpattern(solid) ///
				xline(0, lpattern(.)) yline(0, lpattern(.)) ///
				xsc(range(-5 4)) xmtick(-5(1)4) xlabel(-5(1)4) ///
				ytitle("Log(Deaths per 100,000)") ///
				xtitle(`x_axis_name') ///
				title("Death Rate for `lower_age'- to `upper_age'-Year-Olds") ///
				legend(off) name(estudy_`t'_ageGroup_`group', replace)
				
			save "${savedir}\estudy_`t'_ageGroup_`group'", replace
			
			graph save "${graphdir}\estudy_`t'_ageGroup_`group'.gph", replace
			graph export "${graphdir}\estudy_`t'_ageGroup_`group'.png", replace
			

		restore
	}
	local x_axis_name = "Years Relative to Legalization of Licensed Sale of Recreational Marijuana"
}
