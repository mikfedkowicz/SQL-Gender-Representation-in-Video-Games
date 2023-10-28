/* 
CONTEXT:
This is personal SQL mini-project to showcase possesed skill set, mainly in data manipulation area. Database used is coming from Kaggle website 
and it concerns data connected with gender representation of characters in video games, also including sexualization aspect of them.

Link to the database:
https://www.kaggle.com/datasets/97fe9ea66249f0f8bf795d3906c0ee8913d5164bca3d3fa5820481cf9b73200e

Database consists of three connected tables: 
- 'characters' holds specific data about popular video games characters, such as gender, age, species etc.;
- 'games' holds data concerning particular video games, such as title, publisher, developer, platform or genre;
- 'sexualization' holds data concerning categories in which game characters are sexualized, showing in which aspects it is visible in the game;

Skill set used:
- DDL commands - CREATE, ALTER (MODIFY, RENAME COLUMN)
- DQL commands - SELECT (using keywords WHERE, LIMIT, LIKE, ORDER BY, GROUP BY, CASE WHEN, UNION)
- JOINS
- AGGREGATE FUNCTIONS (COUNT)
- SUBQUERIES
- COMMON TABLE EXPRESSIONS (CTE)
- WINDOW FUNCTIONS (RANK)
- STORED PROCEDURE WITH INPUT PARAMETER
*/

###### PART 1: DATA UPLOADING TO SQL DATABASE AND INITIAL CLEANING
-- First, database 'gender_representation' is created and csv tables are uploaded through Import Wizard in MySQL Workbench.

CREATE DATABASE gender_representation;
USE gender_representation;

-- Then, all invalid and misleading column names in the tables are renamed. 

ALTER TABLE characters
RENAME COLUMN ď»żName TO character_name,
RENAME COLUMN Id TO Character_game_ID;

ALTER TABLE games
RENAME COLUMN ď»żGame_Id TO Game_ID;

ALTER TABLE sexualization
RENAME COLUMN ď»żId TO Character_game_ID;

-- At this moment, primary keys are specified. 

ALTER TABLE characters
MODIFY COLUMN Character_game_ID VARCHAR(255);
ALTER TABLE characters
ADD PRIMARY KEY (Character_game_ID);

ALTER TABLE games
MODIFY COLUMN Game_ID VARCHAR(255);
ALTER TABLE games
ADD PRIMARY KEY (Game_ID);

ALTER TABLE sexualization
MODIFY COLUMN Character_game_ID VARCHAR(255);
ALTER TABLE sexualization
ADD PRIMARY KEY (Character_game_ID);

ALTER TABLE characters
MODIFY COLUMN game VARCHAR(255);

###### PART 2: DATA MANIPULATION

## TASK 1 - SELECT STATEMENT (WITH WHERE, LIMIT, WILDCARD USAGE, AND/OR OPERATORS, ORDER BY)
-- Let's extract from 'characters table' the list of 20 playable characters, which species begins as 'Human', sorted by game code in descending order.

SELECT 
    character_name, gender, game, species
FROM
    characters
WHERE
    playable = 1 AND species LIKE 'human%'
ORDER BY game DESC
LIMIT 20;

## TASK 2a - JOINS
-- As two-letter game abbreviation is not very informative, let's extract exact game title from 'games' table instead -
-- but only if there is match between these two tables. Simultaneously, let's drop limit restriction and search only for human characters.

SELECT 
    c.character_name, c.gender, g.title, c.species
FROM
    characters c
        JOIN
    games g ON g.game_id = c.game
WHERE
    playable = 1 AND species='Human'
ORDER BY game DESC;

## TASK 2b - JOINS
-- On the other hand, let's show titles of the games where 'sexualized clothing' aspect is visible. This will require joining more than two tables.

SELECT DISTINCT
    g.title
FROM
    games g
        JOIN
    characters c ON g.game_id = c.game
        JOIN
    sexualization s ON c.character_game_id = s.character_game_id
WHERE
    s.Sexualized_clothing = 1;

## TASK 3 - AGGREGATE FUNCTIONS + GROUP BY
-- Let's count how many male and female human playable characters are in particular games.

SELECT 
    g.title, c.gender, COUNT(*) as number_of_characters
FROM
    characters c
        JOIN
    games g ON g.game_id = c.game
WHERE
    c.playable = 1 AND c.species='Human'
GROUP BY g.title, c.gender
ORDER BY g.title, number_of_characters DESC;

## TASK 4 - SUBQUERY + WINDOW FUNCTION RANK + UNION
## Let's find out in which games there are most female and male playable characters, dropping species requirement in the meantime.

SELECT * FROM
(SELECT 
    g.title,
    c.gender,
    COUNT(c.character_name) AS number_of_persons,
    RANK() OVER (PARTITION BY c.gender ORDER BY COUNT(c.character_name) DESC) AS my_rank
FROM
    characters c
        JOIN
    games g ON c.game = g.game_ID
WHERE
    c.gender IN ('Female')
        AND c.playable = 1
GROUP BY c.game , c.gender) x
WHERE x.my_rank=1
UNION SELECT * FROM
(SELECT 
    g.title,
    c.gender,
    COUNT(c.character_name) AS number_of_persons,
    RANK() OVER (PARTITION BY c.gender ORDER BY COUNT(c.character_name) DESC) AS my_rank
FROM
    characters c
        JOIN
    games g ON c.game = g.game_ID
WHERE
    c.gender IN ('Male')
        AND c.playable = 1
GROUP BY c.game , c.gender) y
WHERE y.my_rank=1;

## TASK 5 - COMMON TABLE EXPRESSION + CASE WHEN
-- Let's find out which games are really outsatnind ones. In order to do this, let's assign categories to the games according to their Metacritic webpage rating.
-- Such table will be stored temporarily as common table expression 'cte1'. Then we just retrieve the names of 'brilliant' games with rating over 9.5.

WITH cte1 AS (SELECT 
    title,
    (CASE
        WHEN metacritic > 9.5 THEN 'brilliant game'
        WHEN metacritic BETWEEN 8.5 AND 9.5 THEN 'very good game'
        WHEN metacritic BETWEEN 8 AND 8.49 THEN 'good game'
        WHEN metacritic < 8 THEN 'decent game'
        ELSE 'no rating'
    END) AS quality
FROM
    games)
SELECT 
    title
FROM
    cte1
WHERE
    cte1.quality = 'brilliant game';

## TASK 6 - STORED PROCEDURES (WITH INPUT PARAMETER)
-- Let's create a procedure which will show us all the characters' names for specific game, when we populate exact game title.
-- First, let's create select statement which will give us required result, with populating the name of the game manually. 
-- Then, put correct stored procedure syntax in order to create the procedure.
-- At last, let's call the function manually by typing correct command, to check if it is working properly.

SELECT 
    c.character_name
FROM
    characters c
        JOIN
    games g ON c.game = g.game_id
WHERE
    g.title = 'The Witcher 3: Wild Hunt';

DELIMITER $$
CREATE PROCEDURE game_heroes(IN p_game_title VARCHAR(255))
BEGIN

SELECT 
    c.character_name
FROM
    characters c
        JOIN
    games g ON c.game = g.game_id
WHERE
    g.title = p_game_title;

END $$
DELIMITER ;

CALL gender_representation.game_heroes('The Last Of Us');
CALL gender_representation.game_heroes('The Witcher 3: Wild Hunt');

###### PART 3: SUMMARY
/* Data from three tables of database 'Gender representation in video games' has been used to show both fundamental as well as more advanced topics of SQL.
Due to relationships between tables, it was possible to join them (in other case usage of self joins or joins with CTE could be presented).
Most of the task concern data manipulation aspect in order to present required result sets. At the end, stored procedure functionality is shown.
*/