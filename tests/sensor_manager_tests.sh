#!/bin/bash

# Get current list of children - demonstrate only real sensor is present

printf "Start Test\n\n"

printf "Confirm presence of Real Sensor\n"
CHECK_ONE=$(curl localhost:3000/sky/cloud/cklo7m61c000b9mqr3u1v51fh/com.tcashcroft.manage_sensors/sensors 2>/dev/null)
printf "$CHECK_ONE \n\n"

printf "Create Children\n"
SENSOR_1=$(curl localhost:3000/sky/event/cklo7m61c000b9mqr3u1v51fh/default/sensor/new_sensor?name=SENSOR1 2>/dev/null)
SENSOR_2=$(curl localhost:3000/sky/event/cklo7m61c000b9mqr3u1v51fh/default/sensor/new_sensor?name=SENSOR2 2>/dev/null)
SENSOR_3=$(curl localhost:3000/sky/event/cklo7m61c000b9mqr3u1v51fh/default/sensor/new_sensor?name=SENSOR3 2>/dev/null)
CHECK_TWO=$(curl localhost:3000/sky/cloud/cklo7m61c000b9mqr3u1v51fh/com.tcashcroft.manage_sensors/sensors 2>/dev/null)
CHECK_TWO_FORMATTED=$(echo $CHECK_TWO | sed 's/,/,\n/g')
printf "$CHECK_TWO_FORMATTED\n\n"

sleep 2

printf "Delete SENSOR2\n"
SENSOR_2_DELETED=$(curl localhost:3000/sky/event/cklo7m61c000b9mqr3u1v51fh/default/sensor/unneeded_sensor?sensor_name=SENSOR2 2>/dev/null)
CHECK_THREE=$(curl localhost:3000/sky/cloud/cklo7m61c000b9mqr3u1v51fh/com.tcashcroft.manage_sensors/sensors 2>/dev/null)
CHECK_THREE_FORMATTED=$(echo $CHECK_THREE | sed 's/,/,\n/g')
printf "$CHECK_THREE_FORMATTED\n\n"

sleep 2

printf "Get Temperatures - 1\n"
CHECK_FOUR=$(curl localhost:3000/sky/cloud/cklo7m61c000b9mqr3u1v51fh/com.tcashcroft.manage_sensors/temperatures 2>/dev/null)
CHECK_FOUR_FORMATTED=$(echo $CHECK_FOUR | sed 's/,/,\n/g')
printf "$CHECK_FOUR_FORMATTED\n\n"

sleep 2

printf "Get Profiles - before update\n"
PROFILES=$(curl localhost:3000/sky/cloud/cklo7m61c000b9mqr3u1v51fh/com.tcashcroft.manage_sensors/profiles 2>/dev/null)
PROFILES_FORMATTED=$(echo $PROFILES | sed 's/,/,\n/g')
printf "$PROFILES_FORMATTED\n\n"

sleep 2

printf "Changing SENSOR1 profile\n"
UPDATE_PROFILES=$(curl "localhost:3000/sky/event/cklo7m61c000b9mqr3u1v51fh/default/sensor/profile_update_requested?sensorName=SENSOR1&threshold=62&targetPhoneNumber='6233497009'" 2>/dev/null)
PROFILES2=$(curl localhost:3000/sky/cloud/cklo7m61c000b9mqr3u1v51fh/com.tcashcroft.manage_sensors/profiles 2>/dev/null)
PROFILES2_FORMATTED=$(echo $PROFILES2 | sed 's/,/,\n/g')
printf "$PROFILES2_FORMATTED\n\n"

printf "Sleeping for 20 seconds then retrieving temperatures again"
sleep 20


printf "Get Temperatures - 1\n\n"
CHECK_FIVE=$(curl localhost:3000/sky/cloud/cklo7m61c000b9mqr3u1v51fh/com.tcashcroft.manage_sensors/temperatures 2>/dev/null)
CHECK_FIVE_FORMATTED=$(echo $CHECK_FIVE | sed 's/,/,\n/g')
printf "\n\n$CHECK_FIVE_FORMATTED\n\n"

sleep 2

printf "Removing SENSOR1 and SENSOR2"
DELETE_SENSOR1=$(curl localhost:3000/sky/event/cklo7m61c000b9mqr3u1v51fh/default/sensor/unneeded_sensor?sensor_name=SENSOR1 2>/dev/null)
DELETE_SENSOR3=$(curl localhost:3000/sky/event/cklo7m61c000b9mqr3u1v51fh/default/sensor/unneeded_sensor?sensor_name=SENSOR3 2>/dev/null)
SENSORS_FINAL=$(curl localhost:3000/sky/cloud/cklo7m61c000b9mqr3u1v51fh/com.tcashcroft.manage_sensors/sensors 2>/dev/null)
printf "$SENSORS_FINAL\n\nTesting Complete\n"

exit


