# MakestagramFIRE

The makestagram tutorial from Make School's online academy ported to Firebase

## Data structure

In order to make efficient Firebase queries, the data structure had to be as flat as possible. Also functionalities like search and follow required me to have separate entries in the JSON tree in order to be efficiently implemented.

Final data structure:

![Image of Data Structure]
(https://github.com/Kylar13/MakestagramFIRE/blob/final/Data%20Structure.png?raw=true)

* **allUsers**: A list of all users using their key as key and username as value.
* **follows**: A list of follow relations, where the first key indicates a user and the list nested in that user's key represents all the users he follows, using [userKey: invertedTimestamp].
* **isFollowedBy**: The same as "follows", but the list nested in a user's key represents the users that follow him.
* **likes**: The full list of all likes relations, where the first key indicates a post's key and the nested values represent the user's who likes that post. In the user we nest the inverted timestamp and the username of the user for an easier retrieval.
* **posts**: List of all posts in our application, identified by an automatically generated key that contains all the information needed: author username and key, inverted timestamp and image path where the image is stored.
* **search**: The same thing as allUsers but with the usernames in lowercase for faster searching.
* **timeline**: List of user's keys with a list of posts as a value. All the posts from himself and the users he follows are stored there with a timestamp in order to make it easier to gather the posts that need to be displayed on the timeline. Having this separated makes it so everytime a user makes a new post, the timelines of all people who follow him get updated. Also everytime a user follows another user, all their posts get added to the timeline of the user who followed them.
* **users**: A list of users with all their posts nested under it
