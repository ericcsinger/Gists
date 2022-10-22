####################################
#START: Import Data

$ISO3166_1 = Import-Csv -Path ".\ISO3166_1.csv"
$ISO3166_2 = Get-Content -Path ".\loc221csv\2022-1 SubdivisionCodes.csv" -Encoding oem | ConvertFrom-Csv
$ISO3166_2 = Import-Csv -Path ".\loc221csv\2022-1 SubdivisionCodes.csv"  
$AllCapitals = Import-CSV -Path ".\ip2location-country-information-basic\IP2LOCATION-COUNTRY-INFORMATION-BASIC.CSV"
$AllCountryInformation = Import-Csv -Path ".\ip2location-geonameid\IP2LOCATION-GEONAMEID.CSV"



#END: Import Data
####################################

####################################
#START: Join Data
$AllLocationInformationJoined = Foreach ($Country in $ISO3166_1)
    {
    $Subdivisions = $null
    $Subdivisions = $ISO3166_2 | Where-Object {$PSItem.'iso3166-1_alpha2' -eq $Country.alpha2}

    $CountryInformation = $null
    $CountryInformation = $AllCountryInformation | Where-Object {$PSItem.'iso3166-1_alpha2' -eq $Country.alpha2}

    $Capital = $null
    $Capital = $AllCapitals | Where-Object {$PSItem.'country_code' -eq $Country.alpha2}

    [pscustomobject][ordered]@{
        'iso3166-1_alpha2' = $Country.alpha2.ToLower()
        'iso3166-1_alpha3' = $Country.alpha3.ToLower()
        'iso3166-1_name' = $Country.name
        'iso3166-1_numeric' = $Country.numeric
        capital = $($Capital.capital)
        allCountryInformation = Foreach ($CountryInfo in $CountryInformation)
            {
            [pscustomobject][ordered]@{
                regionName = $($CountryInfo.Region_Name).Trim()
                cityName = $($CountryInfo.City_Name).Trim()
                }
            }

        allSubdivisions = Foreach ($sub in $Subdivisions)
            {
            [pscustomobject][ordered]@{
                'iso3166-2_code' = "$($sub.'iso3166-1_alpha2')-$($sub.'iso3166-2_code')".ToLower().Trim()
                'iso3166-2_name' = $($sub.'iso3166-2_name').Trim()
                'iso3166-2_type' = $($sub.'iso3166-2_type').Trim()
                }
            }
        }

    }
#END: Join Data
####################################

####################################
#START: Create HashTable
$AllLocationInformationJoinedHashTable = $null
$AllLocationInformationJoinedHashTable = [ordered]@{}

Foreach ($Location in $AllLocationInformationJoined)
    {
    $LocationObject = $null
    $LocationObject = [ordered]@{
        'iso3166-1_alpha2' = $Location.'iso3166-1_alpha2'
        'iso3166-1_alpha3' = $Location.'iso3166-1_alpha3'
        'iso3166-1_name' = $Location.'iso3166-1_name'
        'iso3166-1_numeric' = $Location.'iso3166-1_numeric'
        capital = $($Location.capital)
        allSubdivisions = [ordered]@{}
        allCountryInformation = [ordered]@{}
        }

    Foreach ($Sub in $Location.allSubdivisions)
        {
        $SubObject = $null
        $SubObject = [ordered]@{
            'iso3166-2_code' = $Sub.'iso3166-2_code'
            'iso3166-2_name' = $Sub.'iso3166-2_name'
            'iso3166-2_type' = $Sub.'iso3166-2_type'
            }
        if ($LocationObject.allSubdivisions.Keys -contains $Sub.'iso3166-2_code')
            {
            $LocationObject.allSubdivisions.$($Sub.'iso3166-2_code') = $SubObject
            }
        else 
            {
            $LocationObject.allSubdivisions.Add($Sub.'iso3166-2_code', $SubObject) 
            }
        
        }

    Foreach ($CountryInfo in $Location.allCountryInformation)
        {
        $CountryInfoObject = $null
        $CountryInfoObject = [ordered]@{
            'iso3166-2_name' = $CountryInfoObject.regionName
            'iso3166-2_type' = $CountryInfoObject.cityName
            }
        $LocationObject.allSubdivisions.Add("$($CountryInfo.regionName)_$($CountryInfo.CityName)", $CountryInfoObject) 
        }

    $AllLocationInformationJoinedHashTable.add($Location.'iso3166-1_alpha3', $LocationObject)

    }

#END: Create HashTable
####################################

####################################
#START: Export Data

$AllLocationInformationJoined | ConvertTo-Json -Depth 100 | Out-File -FilePath ".\AllLocationInformationJoined.json"
$AllLocationInformationJoinedHashTable | ConvertTo-Json -Depth 100 | Out-File -FilePath ".\AllLocationInformationJoinedHashTable.json"


#END: Export Data
####################################