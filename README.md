# Weather Forecast Application
## Overview
This Ruby on Rails project is designed to retrieve and display weather forecast data for a given address.
It focuses on backend functionality, prioritizing the retrieval and caching of weather data.

## Features
* Address Input: Accepts user input for addresses.
* Forecast Retrieval: Fetches forecast data for the input address, including current temperature.
* Extended Forecast: (Optional) Retrieves high/low temperatures and extended forecast details.
* Data Display: Showcases the requested forecast details to the user.
* Caching: Implements a 30-minute caching mechanism for forecast details by zip codes, displaying an indicator if the result is from the cache.
## Installation
Instructions on how to install any dependencies for running the project.

```bash
sudo apt-get install redis-server
bundle
./bin/rails s
```
## Usage

```bash
curl -X GET -H 'Content-Type: application/json' localhost:3000/forecasts/search?address=123+Fake+St+Seattle+Washington
```

### Output
```json
{"data":{"type":"forecast","id":"98115","attributes":{"current_temperature":52},"links":{"self":"http://localhost:3000/api/v1/forecasts/search.json?zip_code=98115"}}}
```
## Testing

```bash
./bin/rails test
```

## References

* https://geocode.maps.co/
* https://www.weather.gov/documentation/services-web-api/