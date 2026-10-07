#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo "Enter your username:"
read -r USERNAME

USERNAME_SQL=${USERNAME//\'/\'\'}
USER_DATA=$($PSQL "SELECT games_played || '|' || COALESCE(best_game, 0) FROM users WHERE username='$USERNAME_SQL'")

if [[ -n "$USER_DATA" ]]; then
  GAMES_PLAYED=${USER_DATA%%|*}
  BEST_GAME=${USER_DATA#*|}
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
else
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  $PSQL "INSERT INTO users(username) VALUES('$USERNAME_SQL')" > /dev/null
fi

SECRET_NUMBER=$((RANDOM % 1000 + 1))
NUMBER_OF_GUESSES=0

echo "Guess the secret number between 1 and 1000:"
read -r GUESS

while true; do
  ((NUMBER_OF_GUESSES += 1))

  if [[ ! "$GUESS" =~ ^[+-]?[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
  else
    if [[ "$GUESS" == -* ]]; then
      GUESS_NUMBER=$((-10#${GUESS#-}))
    else
      GUESS_NUMBER=$((10#${GUESS#+}))
    fi

    if (( GUESS_NUMBER == SECRET_NUMBER )); then
      break
    elif (( GUESS_NUMBER > SECRET_NUMBER )); then
      echo "It's lower than that, guess again:"
    else
      echo "It's higher than that, guess again:"
    fi
  fi

  read -r GUESS
done

echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
$PSQL "UPDATE users SET games_played = games_played + 1, best_game = LEAST(COALESCE(best_game, $NUMBER_OF_GUESSES), $NUMBER_OF_GUESSES) WHERE username='$USERNAME_SQL'" > /dev/null
