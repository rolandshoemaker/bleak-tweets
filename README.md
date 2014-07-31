bleak-tweets
============

a program to cull bleak tweets and images and combine them, posting them to a tumblr

dependency: the tumblr-rb ruby gem (http://blog.markwunsch.com/post/441371943/tumblr-rb)

This program was designed as kind of a jokey mixed-media art project to capture the banality of twitter use.
Based on a list of 'emotionally bleak' words it searches twitter using weighted probability for tweets
using hashtags that contain these words, once it finds a tweet that it has never used before it uses the
Google Image Search API to find an image it hasn't used before, using the hash tag as the search terms.

With both of these the program then combines them into a single image displaying the tweet over the image result. 
It then posts it to a tumblr page, sometimes producing very funny results, sometimes extremely bleak, 
once every 20 minutes for as long as it runs.

currently posts to http://bleak-tweets.tumblr.com/
