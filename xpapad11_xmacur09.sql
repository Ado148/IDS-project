 BEGIN
  FOR i IN (SELECT * FROM user_tables)
  LOOP
    EXECUTE IMMEDIATE ('DROP TABLE ' || i.table_name || ' CASCADE CONSTRAINTS');
  END LOOP;
END;
/

DROP SEQUENCE SEQ_user_id;
DROP SEQUENCE SEQ_conversation_id;
DROP SEQUENCE SEQ_message_id;
DROP SEQUENCE SEQ_post_id;
DROP SEQUENCE SEQ_tag_id;
DROP SEQUENCE SEQ_event_id;
DROP SEQUENCE SEQ_user_event_id;
DROP SEQUENCE SEQ_multimedia_id;
DROP SEQUENCE SEQ_multimedia_user_id;
DROP SEQUENCE SEQ_multimedia_post_id;
DROP SEQUENCE SEQ_photo_album_id;
DROP SEQUENCE SEQ_photo_album_photo_id;
DROP SEQUENCE SEQ_photo_id;
DROP SEQUENCE SEQ_video_id;
DROP SEQUENCE SEQ_conversation_participant_id;
DROP SEQUENCE SEQ_friendship_id;
DROP SEQUENCE SEQ_relation_id;

CREATE TABLE UserTable (
    user_id INT PRIMARY KEY,
    user_name VARCHAR(255) NOT NULL,
    surname VARCHAR(255) NOT NULL,
    date_of_birth DATE NOT NULL,
    sex VARCHAR(1),
    user_address VARCHAR(255),
    education VARCHAR(255),
    email VARCHAR(255),
    CONSTRAINT CHECK_EMAIL CHECK ( REGEXP_LIKE(email, '^[a-zA-Z0-9_!#$%&*+/=?`{|}~^.-]+@[a-zA-Z0-9.-]+$') ),
    phone_number VARCHAR(20),
    CONSTRAINT CHECK_TELEFON CHECK 
        ( REGEXP_LIKE(phone_number, '^((\+420\s?|00420\s?)|(\+421\s?|00421\s?))?[0-9]{3}\s?[0-9]{3}\s?[0-9]{3}$') )
);
    
CREATE TABLE Relation_Table (
    relation_id INT PRIMARY KEY,
    relation_type VARCHAR(31),
    user_one INT NOT NULL,
    user_two INT NOT NULL,
    CONSTRAINT fk_user_one_relation FOREIGN KEY (user_one) REFERENCES UserTable(user_id),
    CONSTRAINT fk_user_two_relation FOREIGN KEY (user_two) REFERENCES UserTable(user_id),
    CHECK (user_one != user_two)
);

CREATE TABLE Friendship_Table (
    friendship_id INT PRIMARY KEY,
    user_one INT NOT NULL,
    user_two INT NOT NULL,
    CONSTRAINT fk_user_one_friendship FOREIGN KEY (user_one) REFERENCES UserTable(user_id),
    CONSTRAINT fk_user_two_friendship FOREIGN KEY (user_two) REFERENCES UserTable(user_id),
    CHECK (user_one != user_two)
);

CREATE TABLE Conversation_Table(
    conversation_id INT PRIMARY KEY,
    conversation_name VARCHAR(255),
    creator INT NOT NULL,
    CONSTRAINT fk_conversation_creator FOREIGN KEY (creator) REFERENCES UserTable(user_id)  
);

CREATE TABLE Conversation_to_participant_Table(
    conversation_participant_id INT PRIMARY KEY,
    convo INT NOT NULL,
    participant INT NOT NULL,
    CONSTRAINT fk_conversation FOREIGN KEY (convo) REFERENCES Conversation_Table(conversation_id),
    CONSTRAINT fk_participant FOREIGN KEY (participant) REFERENCES UserTable(user_id)
    --CHECK (convo != participant)
);

CREATE TABLE Message_Table_Weak(
    message_id INT NOT NULL,
    message_content CLOB NOT NULL,
    date_time TIMESTAMP NOT NULL,
    message_location VARCHAR(127),
    author_msg INT NOT NULL,
    msg_contains INT NOT NULL,
    PRIMARY KEY (message_id, author_msg),
    CONSTRAINT fk_conversation_msg_weak FOREIGN KEY (author_msg) REFERENCES UserTable(user_id),
    CONSTRAINT fk_message_msg_contains_weak FOREIGN KEY (msg_contains) REFERENCES Conversation_Table(conversation_id)
);


CREATE TABLE PostTable(
    post_id INT PRIMARY KEY,
    post_content CLOB NOT NULL,
    date_time TIMESTAMP NOT NULL,
    post_location VARCHAR(127),
    author INT NOT NULL,
    CONSTRAINT fk_post_author FOREIGN KEY (author) REFERENCES UserTable(user_id)
);

CREATE TABLE UserPostTable(
    tag_id INT PRIMARY KEY,
    tagged_user INT NOT NULL,
    post INT NOT NULL,
    CONSTRAINT fk_tagged_user FOREIGN KEY (tagged_user) REFERENCES UserTable(user_id),
    CONSTRAINT fk_post FOREIGN KEY (post) REFERENCES PostTable(post_id)
);

CREATE TABLE EventTable(
    event_id INT PRIMARY KEY,
    event_name VARCHAR(127),
    date_time TIMESTAMP NOT NULL,
    event_location VARCHAR(127),
    creator INT NOT NULL,
    CONSTRAINT fk_creator FOREIGN KEY (creator) REFERENCES UserTable(user_id)
);

CREATE TABLE UserEventTable(
    user_event_id INT PRIMARY KEY,
    user_id INT NOT NULL,
    event_id INT NOT NULL,
    CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES UserTable(user_id),
    CONSTRAINT fk_event_id FOREIGN KEY (event_id) REFERENCES EventTable(event_id)
);

/*  Arc-type implementation
    https://stackoverflow.com/questions/7028613/represent-generalization-in-oracle-sql

    MultimediaPhoto and MultimediaVideo are the leaf nodes of the generalization tree.
    MultimediaTable is the root node of the generalization tree.
    MultimediaTable has two foreign keys to the leaf nodes, only one of which can be not null.
 */

CREATE TABLE MultimediaPhoto(
    photo_id INT PRIMARY KEY,
    tag VARCHAR(127)    
);

CREATE TABLE MultimediaVideo(
    video_id INT PRIMARY KEY,
    video_name VARCHAR(127),
    muted NUMBER(1,0)
);

CREATE TABLE MultimediaTable(
    multimedia_id INT PRIMARY KEY,
    date_time TIMESTAMP NOT NULL,
    multimedia_location VARCHAR(127),
    author INT NOT NULL,
    at_event INT,
    CONSTRAINT fk_author FOREIGN KEY (author) REFERENCES UserTable(user_id),
    CONSTRAINT fk_event FOREIGN KEY (at_event) REFERENCES EventTable(event_id),
    photo_id_FK INT,
    video_id_FK INT,
    CONSTRAINT fk_photo_id_FK FOREIGN KEY (photo_id_FK) REFERENCES MultimediaPhoto(photo_id),
    CONSTRAINT fk_video_is_FK FOREIGN KEY (video_id_FK) REFERENCES MultimediaVideo(video_id),
    /*check that exactly one of photo_id and video_id is not null*/
    /*  (A OR B) AND NOT (A AND B)  XOR equivalent*/
    CHECK ((photo_id_FK IS NULL OR video_id_FK IS NULL) OR NOT (photo_id_FK IS NULL AND video_id_FK IS NULL)),

    /*check that photo/video is only in one multimedia table*/
    UNIQUE (photo_id_FK),
    UNIQUE (video_id_FK)
);

CREATE TABLE MultimediaUserTable(
    multimedia_user_id INT PRIMARY KEY,
    multimedia_id INT NOT NULL,
    user_id INT NOT NULL,
    CONSTRAINT fk_multimedia_id FOREIGN KEY (multimedia_id) REFERENCES MultimediaTable(multimedia_id),
    CONSTRAINT fk_multimedia_user_id FOREIGN KEY (user_id) REFERENCES UserTable(user_id)
);

CREATE TABLE MultimediaPostTable(
    multimedia_post_id INT PRIMARY KEY,
    multimedia_id INT NOT NULL,
    post_id INT NOT NULL,
    CONSTRAINT fk_multimedia_post_id FOREIGN KEY (multimedia_id) REFERENCES MultimediaTable(multimedia_id),
    CONSTRAINT fk_post_id FOREIGN KEY (post_id) REFERENCES PostTable(post_id)
);

CREATE TABLE PhotoAlbumTable(
    photo_album_id INT PRIMARY KEY,
    album_name VARCHAR(127),
    visibility VARCHAR(31),
    album_description CLOB,
    author INT NOT NULL,
    title_photo INT NOT NULL,
    CONSTRAINT fk_album_author FOREIGN KEY (author) REFERENCES UserTable(user_id),
    CONSTRAINT fk_title_photo FOREIGN KEY (title_photo) REFERENCES MultimediaPhoto(photo_id)
);

CREATE TABLE PhotoAlbumPhotoTable(
    photo_album_photo_id INT PRIMARY KEY,
    photo_album_id INT NOT NULL,
    photo_id INT NOT NULL,
    CONSTRAINT fk_photo_album_id FOREIGN KEY (photo_album_id) REFERENCES PhotoAlbumTable(photo_album_id),
    CONSTRAINT fk_photo_id FOREIGN KEY (photo_id) REFERENCES MultimediaPhoto(photo_id)
);

CREATE SEQUENCE SEQ_user_id INCREMENT BY 1 START WITH 1 NOMAXVALUE MINVALUE 0;
CREATE SEQUENCE SEQ_conversation_id INCREMENT BY 1 START WITH 1 NOMAXVALUE MINVALUE 0;
CREATE SEQUENCE SEQ_message_id INCREMENT BY 1 START WITH 1 NOMAXVALUE MINVALUE 0;
CREATE SEQUENCE SEQ_post_id INCREMENT BY 1 START WITH 1 NOMAXVALUE MINVALUE 0;
CREATE SEQUENCE SEQ_tag_id INCREMENT BY 1 START WITH 1 NOMAXVALUE MINVALUE 0;
CREATE SEQUENCE SEQ_event_id INCREMENT BY 1 START WITH 1 NOMAXVALUE MINVALUE 0;
CREATE SEQUENCE SEQ_user_event_id INCREMENT BY 1 START WITH 1 NOMAXVALUE MINVALUE 0;
CREATE SEQUENCE SEQ_multimedia_id INCREMENT BY 1 START WITH 1 NOMAXVALUE MINVALUE 0;
CREATE SEQUENCE SEQ_multimedia_user_id INCREMENT BY 1 START WITH 1 NOMAXVALUE MINVALUE 0;
CREATE SEQUENCE SEQ_multimedia_post_id INCREMENT BY 1 START WITH 1 NOMAXVALUE MINVALUE 0;
CREATE SEQUENCE SEQ_photo_album_id INCREMENT BY 1 START WITH 1 NOMAXVALUE MINVALUE 0;
CREATE SEQUENCE SEQ_photo_album_photo_id INCREMENT BY 1 START WITH 1 NOMAXVALUE MINVALUE 0;
CREATE SEQUENCE SEQ_photo_id INCREMENT BY 1 START WITH 1 NOMAXVALUE MINVALUE 0;
CREATE SEQUENCE SEQ_video_id INCREMENT BY 1 START WITH 1 NOMAXVALUE MINVALUE 0;
CREATE SEQUENCE SEQ_conversation_participant_id INCREMENT BY 1 START WITH 1 NOMAXVALUE MINVALUE 0;
CREATE SEQUENCE SEQ_friendship_id INCREMENT BY 1 START WITH 1 NOMAXVALUE MINVALUE 0;
CREATE SEQUENCE SEQ_relation_id INCREMENT BY 1 START WITH 1 NOMAXVALUE MINVALUE 0;

-- Auto increment triggers
CREATE OR REPLACE TRIGGER TR_user_id BEFORE INSERT ON UserTable FOR EACH ROW
begin
  if :new.user_id is null then 
    SELECT SEQ_user_id.nextval INTO :new.user_id FROM DUAL; 
  end if; 
end TR_user_id;
/

CREATE OR REPLACE TRIGGER TR_conversation_id BEFORE INSERT ON Conversation_Table FOR EACH ROW
begin
  if :new.conversation_id is null then 
    SELECT SEQ_conversation_id.nextval INTO :new.conversation_id FROM DUAL; 
  end if; 
end TR_conversation_id;
/

CREATE OR REPLACE TRIGGER TR_message_id BEFORE INSERT ON Message_Table_Weak FOR EACH ROW
begin
  if :new.message_id is null then 
    SELECT SEQ_message_id.nextval INTO :new.message_id FROM DUAL; 
  end if; 
end TR_message_id;
/

CREATE OR REPLACE TRIGGER TR_post_id BEFORE INSERT ON PostTable FOR EACH ROW
begin
  if :new.post_id is null then 
    SELECT SEQ_post_id.nextval INTO :new.post_id FROM DUAL; 
  end if; 
end TR_post_id;
/

CREATE OR REPLACE TRIGGER TR_tag_id BEFORE INSERT ON UserPostTable FOR EACH ROW
begin
  if :new.tag_id is null then 
    SELECT SEQ_tag_id.nextval INTO :new.tag_id FROM DUAL; 
  end if; 
end TR_tag_id;
/

CREATE OR REPLACE TRIGGER TR_event_id BEFORE INSERT ON EventTable FOR EACH ROW
begin
  if :new.event_id is null then 
    SELECT SEQ_event_id.nextval INTO :new.event_id FROM DUAL; 
  end if; 
end TR_event_id;
/

CREATE OR REPLACE TRIGGER TR_user_event_id BEFORE INSERT ON UserEventTable FOR EACH ROW
begin
  if :new.user_event_id is null then 
    SELECT SEQ_user_event_id.nextval INTO :new.user_event_id FROM DUAL; 
  end if; 
end TR_user_event_id;
/

CREATE OR REPLACE TRIGGER TR_multimedia_id BEFORE INSERT ON MultimediaTable FOR EACH ROW
begin
  if :new.multimedia_id is null then 
    SELECT SEQ_multimedia_id.nextval INTO :new.multimedia_id FROM DUAL; 
  end if; 
end TR_multimedia_id;
/

CREATE OR REPLACE TRIGGER TR_multimedia_user_id BEFORE INSERT ON MultimediaUserTable FOR EACH ROW
begin
  if :new.multimedia_user_id is null then 
    SELECT SEQ_multimedia_user_id.nextval INTO :new.multimedia_user_id FROM DUAL; 
  end if; 
end TR_multimedia_user_id;
/

CREATE OR REPLACE TRIGGER TR_multimedia_post_id BEFORE INSERT ON MultimediaPostTable FOR EACH ROW
begin
  if :new.multimedia_post_id is null then 
    SELECT SEQ_multimedia_post_id.nextval INTO :new.multimedia_post_id FROM DUAL; 
  end if; 
end TR_multimedia_post_id;
/

CREATE OR REPLACE TRIGGER TR_photo_album_id BEFORE INSERT ON PhotoAlbumTable FOR EACH ROW
begin
  if :new.photo_album_id is null then 
    SELECT SEQ_photo_album_id.nextval INTO :new.photo_album_id FROM DUAL; 
  end if; 
end TR_photo_album_id;
/

CREATE OR REPLACE TRIGGER TR_photo_album_photo_id BEFORE INSERT ON PhotoAlbumPhotoTable FOR EACH ROW
begin
  if :new.photo_album_photo_id is null then 
    SELECT SEQ_photo_album_photo_id.nextval INTO :new.photo_album_photo_id FROM DUAL; 
  end if; 
end TR_photo_album_photo_id;
/

CREATE OR REPLACE TRIGGER TR_photo_id BEFORE INSERT ON MultimediaPhoto FOR EACH ROW
begin
  if :new.photo_id is null then 
    SELECT SEQ_photo_id.nextval INTO :new.photo_id FROM DUAL; 
  end if; 
end TR_photo_id;
/

CREATE OR REPLACE TRIGGER TR_video_id BEFORE INSERT ON MultimediaVideo FOR EACH ROW
begin
  if :new.video_id is null then 
    SELECT SEQ_video_id.nextval INTO :new.video_id FROM DUAL; 
  end if; 
end TR_video_id;
/

CREATE OR REPLACE TRIGGER TR_conversation_participant_id BEFORE INSERT ON Conversation_to_participant_Table FOR EACH ROW
begin
  if :new.conversation_participant_id is null then 
    SELECT SEQ_conversation_participant_id.nextval INTO :new.conversation_participant_id FROM DUAL; 
  end if; 
end TR_conversation_participant_id;
/

CREATE OR REPLACE TRIGGER TR_friendship_id BEFORE INSERT ON Friendship_Table FOR EACH ROW
begin
  if :new.friendship_id is null then 
    SELECT SEQ_friendship_id.nextval INTO :new.friendship_id FROM DUAL; 
  end if; 
end TR_friendship_id;
/

CREATE OR REPLACE TRIGGER TR_relation_id BEFORE INSERT ON Relation_Table FOR EACH ROW
begin
  if :new.relation_id is null then 
    SELECT SEQ_relation_id.nextval INTO :new.relation_id FROM DUAL; 
  end if; 
end TR_relation_id;
/

/*-------------------------------------------Trigger----------------------------------------------------*/
DROP TRIGGER validate_email;

CREATE OR REPLACE TRIGGER validate_email
BEFORE INSERT OR UPDATE OF email ON UserTable
FOR EACH ROW
BEGIN
    IF :NEW.email IS NULL THEN
        :NEW.email := :NEW.user_name || '@example.com';
    ELSIF NOT REGEXP_LIKE(:NEW.email, '^[a-zA-Z0-9_!#$%&*+/=?`{|}~^.-]+@[a-zA-Z0-9.-]+$') THEN
        RAISE_APPLICATION_ERROR(-20002, 'Nespravny format emailu.');
    END IF;
END;
/

/*----------------------------------------------------INSERTS----------------------------------------------------*/
/*USERS*/
INSERT INTO UserTable(user_name, surname, date_of_birth, sex, user_address, education, email, phone_number) 
VALUES('John', 'Doe', '01-JAN-03', '1', 'Praha 15', 'Elementary education', 'johndoe@gmail.com', '+420 555 555 555');

INSERT INTO UserTable(user_name, surname, date_of_birth, sex, user_address, education, email, phone_number) 
VALUES('John', 'Marston', '15-DEC-02', '1', 'Brno 45', 'Higher education', 'johnmarston@gmail.com', '+421 555 444 555');

INSERT INTO UserTable(user_name, surname, date_of_birth, sex, user_address, education, email, phone_number) 
VALUES('Janko', 'Mrkvicka', '06-JAN-01', '1', 'Olomouc 1', 'University education', 'jankomrkvicka@gmail.com', '+420 981 111 222');

INSERT INTO UserTable(user_name, surname, date_of_birth, sex, user_address, education, email, phone_number) 
VALUES('Martin', 'Nitran', '08-JAN-11', '1', 'Bratislava 11', 'University education', 'martinnitran@gmail.com', '+421 999 995 455');

INSERT INTO UserTable(user_name, surname, date_of_birth, sex, user_address, education, email, phone_number) 
VALUES('Jane', 'Doe', '10-MAR-02', '0', 'Vyškov 9', 'Higher education', 'janedoe@gmail.com', '+420 888 789 555');

INSERT INTO UserTable(user_name, surname, date_of_birth, sex, user_address, education, email, phone_number) 
VALUES('Jane', 'Does', '19-FEB-70', '0', 'Brno 20', 'University education, Higher education', 'jane041@gmail.com', '+420 888 777 515');

INSERT INTO UserTable(user_name, surname, date_of_birth, user_address, education, email, phone_number) 
VALUES('Arthur', 'Monrou', '05-FEB-03', 'Brno 148', 'Higner education', 'monrou@gmail.com', '+420 444 155 955');

/*Otestovanie funkcnosti triggerov*/
INSERT INTO UserTable(user_name, surname, date_of_birth, sex, user_address, education, email, phone_number) 
VALUES('TEST', 'TEST', '01-JAN-03', '1', 'Praha 15', 'Elementary education', '', '+420 555 555 555');


/*RELATIONS*/
INSERT INTO Relation_Table(relation_type, user_one, user_two) VALUES('Friends', '3', '4');

INSERT INTO Relation_Table(relation_type, user_one, user_two) VALUES('Family', '1', '2');

INSERT INTO Relation_Table(relation_type, user_one, user_two) VALUES('Closer relationship', '5', '4');

/*FRIENDSHIP*/
INSERT INTO Friendship_Table(user_one, user_two) VALUES('3', '4');

INSERT INTO Friendship_Table(user_one, user_two) VALUES('1', '2');

INSERT INTO Friendship_Table(user_one, user_two) VALUES('5', '4');

/*CONVERSATION*/
INSERT INTO Conversation_Table(conversation_name, creator) VALUES('Info', '1');

INSERT INTO Conversation_Table(conversation_name, creator) VALUES('Where to go', '3');

INSERT INTO Conversation_Table(conversation_name, creator) VALUES('What else do you need to buy ?', '5');

/*CONVERSATION TO PARTICIPANT TABLE*/
INSERT INTO Conversation_to_participant_Table(convo, participant) VALUES('1', '3');

INSERT INTO Conversation_to_participant_Table(convo, participant) VALUES('1', '1');

INSERT INTO Conversation_to_participant_Table(convo, participant) VALUES('2', '2');

INSERT INTO Conversation_to_participant_Table(convo, participant) VALUES('3', '5');

INSERT INTO Conversation_to_participant_Table(convo, participant) VALUES('3', '4');

/*MESSAGE WEAK*/
INSERT INTO Message_Table_Weak(message_content, date_time, message_location, author_msg, msg_contains) 
VALUES('Car is here.', '09-01-2010 21:24:00', 'Brno', '3', '1');

INSERT INTO Message_Table_Weak(message_content, date_time, message_location, author_msg, msg_contains) 
VALUES('Where should I wait for you ?', '10-01-2010 21:24:00', 'Brno', '2', '2');

INSERT INTO Message_Table_Weak(message_content, date_time, message_location, author_msg, msg_contains) 
VALUES('Do you need some fruit or vegetables ?', '10-01-2011 21:24:00', 'Brno', '5', '3');

INSERT INTO Message_Table_Weak(message_content, date_time, message_location, author_msg, msg_contains) 
VALUES('Yes and some milk please.', '10-01-2011 21:25:35', 'Brno', '4', '3');

INSERT INTO Message_Table_Weak(message_content, date_time, message_location, author_msg, msg_contains) 
VALUES('Ok no problem', '10-01-2011 21:25:35', 'Brno', '5', '3');

/*POST*/
INSERT INTO PostTable(post_content, date_time, post_location, author) VALUES('Some text and images/videoes.', '09-01-2010 21:24:00', 'Brno', '3');

INSERT INTO PostTable(post_content, date_time, post_location, author) VALUES('Some text and images/videoes.', '10-01-2010 21:24:00', 'Brno', '2');

INSERT INTO PostTable(post_content, date_time, post_location, author) VALUES('Some text and images/videoes.', '10-01-2011 21:24:00', 'Brno', '5');

/*POST TABLE*/
INSERT INTO UserPostTable(tagged_user, post) VALUES('4', '1');

INSERT INTO UserPostTable(tagged_user, post) VALUES('1', '2');

INSERT INTO UserPostTable(tagged_user, post) VALUES('3', '3');

/*EVENT*/
INSERT INTO EventTable(event_name, date_time, event_location, creator) VALUES('New Year', '01-01-2011 21:24:00', 'Brno', '3'); /*third user from */

INSERT INTO EventTable(event_name, date_time, event_location, creator) VALUES('START@FIT', '09-09-2010 8:00:00', 'Brno', '2');

INSERT INTO EventTable(event_name, date_time, event_location, creator) VALUES('Imatriculations', '12-10-2011 10:00:00', 'Brno', '5');

INSERT INTO EventTable(event_name, date_time, event_location, creator) VALUES('Imatriculations', '12-10-2011 10:00:00', 'Praha', '5');

INSERT INTO EventTable(event_name, date_time, event_location, creator) VALUES('Imatriculations', '12-10-2012 10:00:00', 'Zlin', '2');

/*USER EVENT TABLE*/
INSERT INTO UserEventTable(user_id, event_id) VALUES('3', '1');

INSERT INTO UserEventTable(user_id, event_id) VALUES('2', '2');

INSERT INTO UserEventTable(user_id, event_id) VALUES('5', '3');

INSERT INTO UserEventTable(user_id, event_id) VALUES('5', '4');

INSERT INTO UserEventTable(user_id, event_id) VALUES('5', '5');

/*MULTIMEDIA PHOTO*/
INSERT INTO MultimediaPhoto(tag) VALUES('#newyear');

INSERT INTO MultimediaPhoto(tag) VALUES('#start@fit');

INSERT INTO MultimediaPhoto(tag) VALUES('#fitimatriculations');

/*MULTIMEDIA VIDEO*/
INSERT INTO MultimediaVideo(video_name, muted) VALUES('New year video', '0');

INSERT INTO MultimediaVideo(video_name, muted) VALUES('Start of despair', '0');

INSERT INTO MultimediaVideo(video_name, muted) VALUES('Video from FIT imatriculations', '0');

/*MULTIMEDIA ELEMENT*/
INSERT INTO MultimediaTable(date_time, multimedia_location, author, at_event, photo_id_FK, video_id_FK) VALUES('05-01-2011 10:20:16', 'Brno', '3', '1', '1', '1');

INSERT INTO MultimediaTable(date_time, multimedia_location, author, at_event, photo_id_FK, video_id_FK) VALUES('20-09-2011 20:31:00', 'Brno', '2', '2', '2', '2');

INSERT INTO MultimediaTable(date_time, multimedia_location, author, at_event, photo_id_FK, video_id_FK) VALUES('20-10-2011 15:31:00', 'Brno', '5', '3', '3', '3');

/*MULTIMEDIA USER TABLE*/
INSERT INTO MultimediaUserTable(multimedia_id, user_id) VALUES('1', '4');

INSERT INTO MultimediaUserTable(multimedia_id, user_id) VALUES('2', '1');

INSERT INTO MultimediaUserTable(multimedia_id, user_id) VALUES('3', '3');

/*MULTIMEDIA POST TABLE*/
INSERT INTO MultimediaPostTable(multimedia_id, post_id) VALUES('1', '1');

INSERT INTO MultimediaPostTable(multimedia_id, post_id) VALUES('2', '2');

INSERT INTO MultimediaPostTable(multimedia_id, post_id) VALUES('3', '3');

/*PHOTO ALBUM*/
INSERT INTO PhotoAlbumTable(album_name, visibility, album_description, author, title_photo) VALUES('New Year 2011', '', '', '3', '1');

INSERT INTO PhotoAlbumTable(album_name, visibility, album_description, author, title_photo) VALUES('', '', '', '2', '2');

INSERT INTO PhotoAlbumTable(album_name, visibility, album_description, author, title_photo) VALUES('Imatriculations', 'all', '', '5', '3');

/*PHOTO ALBUM PHOTO TABLE*/
INSERT INTO PhotoAlbumPhotoTable(photo_album_id, photo_id) VALUES('1', '2');

INSERT INTO PhotoAlbumPhotoTable(photo_album_id, photo_id) VALUES('2', '3');

INSERT INTO PhotoAlbumPhotoTable(photo_album_id, photo_id) VALUES('3', '2');

/*-------------------------------------------SELECTS----------------------------------------------------*/
/*Vyber mena a typy vzthov ktore moze mat uzivatel Martin Nitran ?*/                /* 2 tablky */
SELECT U.user_name, U.surname, R.relation_type
FROM UserTable U JOIN Relation_Table R ON (U.user_id = R.user_one OR U.user_id = R.user_two)
AND (R.user_one = (SELECT user_id FROM UserTable WHERE user_name = 'Martin' AND surname = 'Nitran')
OR R.user_two = (SELECT user_id FROM UserTable WHERE user_name = 'Martin' AND surname = 'Nitran'))
WHERE NOT (U.user_name = 'Martin' AND U.surname = 'Nitran');/*to filter Martin Nitran from the result*/

/*Ktory uzivatelia zakladali udalosti medzi 9. a 12. mesiacom roku 2011 ?*/         /* 2 tablky */
SELECT U.user_name, U.surname, E.event_name 
FROM EventTable E JOIN UserTable U ON (U.user_id = E.creator)
WHERE date_time  BETWEEN ('01-09-2011 0:00:00') and ('31-12-2011 23:59:59');

/*Kolko priatelstiev a vztahov je maju jednotlivy uzivatelia ? */                   /* 3 tablky */
SELECT user_name, surname, COUNT (DISTINCT(friendship_id)) AS Fr_Count, COUNT(DISTINCT(relation_id)) AS Rel_Count 
FROM UserTable U JOIN Relation_Table R ON (U.user_id = R.user_one OR U.user_id = R.user_two) JOIN Friendship_Table F ON (U.user_id = F.user_one OR U.user_id = F.user_two)
GROUP BY user_name, surname;

/*Kolko sprav poslal aky uzivatel*/                                                 /* group + agregacna */
SELECT user_name, surname, COUNT(message_id)
FROM UserTable U JOIN Message_Table_Weak M ON (U.user_id = M.author_msg)
GROUP BY user_name, surname;


/*Kolko multimedia prvkov vytvoril aky uzivatel*/                                   /* group + agregacna */
SELECT user_name, surname, COUNT(multimedia_id)
FROM UserTable U JOIN MultimediaTable M ON (U.user_id = M.author)
GROUP BY user_name, surname;


/*Vyber uzivatelov ktory su v konverzacii ale neposlali este spravu*/               /* Exists */   
SELECT u.user_name, u.surname
FROM UserTable u
JOIN Conversation_to_participant_Table cp ON u.user_id = cp.participant
WHERE NOT EXISTS (
    SELECT 1
    FROM Message_Table_Weak m
    WHERE m.author_msg = u.user_id
);

/*Ktory uzivatelia sa zucastnili kolkych akcii (event) v roku 2011*/                /* IN */
SELECT user_name, surname
FROM UserTable U
WHERE user_id IN
    (SELECT user_id FROM UserEventTable
    WHERE event_id IN
    (SELECT event_id FROM EventTable
    WHERE date_time BETWEEN ('01-01-2011 0:00:00') and ('31-12-2011 23:59:59')));

/*-------------------------------------------PROCEDURES----------------------------------------------------*/
SET serveroutput ON;

/*Ak nie je definovane pohlavie, nastav ho na 1 (muz) a vypis vsetky riadky v ktorych bola zmena vykonana*/
CREATE OR REPLACE PROCEDURE update_user_procedure IS
CURSOR user_update_cursor IS
SELECT user_id, user_name, surname, email from UserTable WHERE sex IS NULL;
    user_id_fetched UserTable.user_id%TYPE;/*deklaruj premennu rovnakeho datoveho typu ako je user_id stlpec*/
    user_name_print UserTable.user_name%TYPE;/*pomocna premenna na vypis*/
    user_surname_print UserTable.surname%TYPE;/*pomocna premenna na vypis*/
    user_email_print UserTable.email%TYPE;/*pomocna premenna na vypis*/
    affected_rows NUMBER;
BEGIN
affected_rows := 0;

OPEN user_update_cursor;
LOOP
    FETCH user_update_cursor INTO user_id_fetched, user_name_print, user_surname_print, user_email_print;
    EXIT WHEN user_update_cursor%NOTFOUND;
    
    UPDATE UserTable
    SET sex = 1
    WHERE user_id = user_id_fetched;
    affected_rows := affected_rows + SQL%ROWCOUNT; /*Pripocitaj len ak doslko k vykonaniu UPDATE statement*/
    dbms_output.put_line('Upraveny riadok: ' || user_id_fetched || ', ' || user_name_print || ', ' || user_surname_print || ', ' || user_email_print);/*Vypis upraveny riadok*/
END LOOP;

CLOSE user_update_cursor;
dbms_output.put_line('Pocet riadkov ktore sa zmenili ' || affected_rows);
EXCEPTION 
    WHEN OTHERS THEN
        dbms_output.put_line('Neocakavana chyba pri vykonavani procedury update_user_procedure' || SQLERRM);
END;
/
EXECUTE update_user_procedure;



/*Percento muzov, zien a nedefinovanych (Neboli v tabulke najdene ziadne data tykajuce sa pohlavia) v tabulke UserTable*/
CREATE OR REPLACE PROCEDURE male_female_user_percentage (sex IN INT) IS
CURSOR percentage IS 
SELECT * FROM UserTable;
    tmp percentage%ROWTYPE;
    all_users NUMBER;
    all_male_users NUMBER;
    all_female_users NUMBER;
    final_percentage_male NUMBER;
    final_percentage_female NUMBER;
    final_percentage_unknown NUMBER;
    unknown NUMBER; 
BEGIN
all_users := 0;
all_male_users := 0;
all_female_users := 0;
final_percentage_male := 0;
final_percentage_female := 0;
final_percentage_unknown := 0;
unknown := 0;

OPEN percentage;
LOOP
    FETCH percentage into tmp;
    EXIT WHEN percentage%NOTFOUND;
    
    all_users := all_users + 1;
    IF (tmp.sex = 1) THEN
        all_male_users := all_male_users + 1;
    ELSIF (tmp.sex = 0) THEN
        all_female_users := all_female_users + 1;
    ELSE
        unknown := unknown + 1;
    END IF;
END LOOP;

final_percentage_male := (all_male_users / all_users) * 100;
final_percentage_female := (all_female_users / all_users) * 100;
final_percentage_unknown := (unknown / all_users) * 100;

CLOSE percentage; /*Uzavri kurzor*/
/*TO_CHAR() zaokruhli na 2 desatinne miesta*/
dbms_output.put_line('Vsetkych uzivatelov je ' || all_users);
dbms_output.put_line('Z toho muzov je ' || all_male_users || ' percentualne zastupenie muzov medzi uzivatelmi je ' || TO_CHAR(final_percentage_male, '99.99') || ' %.');
dbms_output.put_line('Z toho zien je ' || all_female_users || ' percentualne zastupenie zien medzi uzivatelmi je ' || TO_CHAR(final_percentage_female, '99.99') || ' %.');
dbms_output.put_line('Z toho nedefinovanych je ' || unknown || ' percentualne zastupenie nedefinovanych medzi uzivatelmi je ' || TO_CHAR(final_percentage_unknown, '99.99') || ' %.');
EXCEPTION 
    WHEN ZERO_DIVIDE THEN 
        dbms_output.put_line('Delnie 0');
    WHEN OTHERS THEN
        dbms_output.put_line('Neocakavana chyba pri vykonavani procedury male_female_user_percentage' || SQLERRM);
END;
/
EXECUTE male_female_user_percentage(1);

/*-------------------------------------------ACCESS RIGHTS----------------------------------------------------*/
GRANT ALL ON UserTable TO xpapad11;
GRANT ALL ON UserPostTable TO xmacur09;
GRANT ALL ON UserEventTable TO xmacur09;
GRANT ALL ON Relation_table TO xmacur09;
GRANT ALL ON PostTable TO xmacur09;
GRANT ALL ON PhotoAlbumTable TO xmacur09;
GRANT ALL ON PhotoAlbumPhotoTable TO xmacur09;
GRANT ALL ON MultimediaVideo TO xmacur09;
GRANT ALL ON MultimediaUserTable TO xmacur09;
GRANT ALL ON MultimediaTable TO xmacur09;
GRANT ALL ON MultimediaPostTable TO xmacur09;
GRANT ALL ON MultimediaPhoto TO xmacur09;
GRANT ALL ON Message_table_weak TO xmacur09;
GRANT ALL ON Friendship_table TO xmacur09;
GRANT ALL ON EventTable TO xmacur09;
GRANT ALL ON Conversation_to_participant_table TO xmacur09;
GRANT ALL ON Conversation_table TO xmacur09;

GRANT EXECUTE ON update_user_procedure TO xmacur09;
GRANT EXECUTE ON male_female_user_percentage TO xmacur09;

/*-------------------------------------------Materialized views----------------------------------------------------*/
CREATE MATERIALIZED VIEW LOG ON Conversation_table WITH PRIMARY KEY, ROWID(conversation_name) INCLUDING NEW VALUES;

CREATE MATERIALIZED VIEW conversations
CACHE /*data budu na-cache-ovane do pamate kvoli vykonu*/
BUILD IMMEDIATE /*mater. view by malo mat data hned po jeho vzniku*/
REFRESH FAST ON COMMIT /*v pripade commitu zmeny dat v master tabulke (Conversation_table) by sa pohlad mal obnovit (refresh)*/
ENABLE QUERY REWRITE /*umozni optimalizatoru pouzit materializovany pohlad na prepisanie queries pre zlepsenie vykonu*/
/*Pridaj data do materializovaneho pohladu*/
AS SELECT Conversation_table.conversation_id, Conversation_table.conversation_name, Conversation_table.creator FROM Conversation_table;
GRANT ALL ON conversations TO xpapad11;

SELECT * FROM conversations;
INSERT INTO Conversation_Table(conversation_id, conversation_name, creator) VALUES('4','Is this your house ???', '6');
COMMIT;

SELECT * FROM conversations;
DELETE FROM Conversation_Table WHERE conversation_id = '4';
COMMIT;

SELECT * FROM conversations;

DROP MATERIALIZED VIEW conversations;

/*-------------------------------------------Complex SELECT ----------------------------------------------------*/
/*Dotaz vypocita najprv vek uzivatelov a potom ich rozdeli do jednotlivych skupin podla veku. 
Vysledkom bude tabulka s uzivatelskymi menami, priezviskami, a vekovymi skupinami kuktorym jednotlivy uzivatelia boli zaradeny*/
WITH age_of_users AS (
SELECT user_name, surname,date_of_birth, MONTHS_BETWEEN(SYSDATE,date_of_birth)/12 as Age 
FROM UserTable
)
SELECT user_name, surname,
CASE
    WHEN Age < 18 THEN 'Uzivatel je neplnolety.'
    WHEN Age BETWEEN 18 AND 30 THEN 'Uzivatel s vekom 18-30 rokov.' 
    WHEN Age BETWEEN 31 AND 50 THEN 'Uzivatel s vekom 31-50 rokov.'
    WHEN Age BETWEEN 51 AND 70 THEN 'Uzivatel s vekom 51-70 rokov.'
    WHEN Age BETWEEN 71 AND 100 THEN 'Uzivatel s vekom 71-100 rokov.'
    ELSE 'Uzivatela neobolo mozne zaradit do ziadnej z predoslych vekovych kategorii.'
END AS age_group
FROM age_of_users;

/*-------------------------------------------Explain plan----------------------------------------------------*/
DROP INDEX relation_user_idx;
DROP INDEX friendship_idx;
--DROP INDEX user_idx;

EXPLAIN PLAN FOR
SELECT user_name, surname, COUNT (DISTINCT(friendship_id)) AS Fr_Count, COUNT(DISTINCT(relation_id)) AS Rel_Count 
FROM UserTable U JOIN Relation_Table R ON (U.user_id = R.user_one OR U.user_id = R.user_two) JOIN Friendship_Table F ON (U.user_id = F.user_one OR U.user_id = F.user_two)
GROUP BY user_name, surname;

SELECT * FROM table (dbms_xplan.display());

CREATE INDEX relation_user_idx ON Relation_Table(user_one, user_two);
CREATE INDEX friendship_idx ON Friendship_Table(user_one, user_two);
--CREATE INDEX user_idx ON UserTable(user_id);
--INDEX(UserTable user_idx)

EXPLAIN PLAN FOR
SELECT /*+ INDEX(Relation_Table relation_user_idx) INDEX(Friendship_Table friendship_idx)*/  user_name, surname, COUNT (DISTINCT(friendship_id)) AS Fr_Count, COUNT(DISTINCT(relation_id)) AS Rel_Count 
FROM UserTable U JOIN Relation_Table R ON (U.user_id = R.user_one OR U.user_id = R.user_two) JOIN Friendship_Table F ON (U.user_id = F.user_one OR U.user_id = F.user_two)
GROUP BY user_name, surname;

SELECT * FROM table (dbms_xplan.display());

/*-------------------------------------------Trigger overenie----------------------------------------------------*/
SELECT * FROM UserTable;