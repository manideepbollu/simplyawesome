README
------

Proposed app can be considered as an extension to the Yelp/Zomato applications. While Yelp/Zomato is quite useful for people who want to choose a restaurant to have a meal, this app will be useful for the restaurant owners who like to improve their businesses. 


WORKING
-------

App uses Zomato APIs to fetch real-time data from their servers and analyze it with our restaurant’s data in order to generate a comprehensive market report. By this, we can see how many restaurants are there in the neighborhood which serve the same cuisine, how they charge for various items, what’s the traffic and on top of all this data, we can even perform analysis comparing our own data.

A step by step view:
* We allow a restaurant’s owner to add his business into our app using Google APIs,. bBy this, we can get its verified business name (Google Places API) and location coordinates (Google Maps API).
* With the available business name and location, we can get the details such as cuisine, ratings, reviews, photos, menu etc. from Zomato and Yelp APIs.


```
https://developers.zomato.com/api/v2.1/search?q=<<Business_Name>>&count=5&lat=<<Latitude>>&lon=<<Longitude>>&radius=15000&sort=rating&order=desc", accept: :json, 'user-key' => Rails.application.config.zomato_key
```
```
Example response (JSON):
{
  "results_found": "53",
  "results_start": "11",
  "results_shown": "10",
  "restaurants": [
    {
      "id": "16774318",
      "name": "Otto Enoteca & Pizzeria",
      "url": "https://www.zomato.com/new-york-city/otto-enoteca-pizzeria-greenwich-village",
      "location": {
        "address": "1 5th Avenue, New York, NY 10003",
        "locality": "Greenwich Village",
        "city": "New York City",
        "latitude": "40.732013",
        "longitude": "-73.996155",
        "zipcode": "10003",
        "country_id": "216"
      },
      "average_cost_for_two": "60",
      "price_range": "2",
      "currency": "$",
      "thumb": "https://b.zmtcdn.com/data/pictures/chains/8/16774318/a54deb9e4dbb79dd7c8091b30c642077_featured_thumb.png",
      "featured_image": "https://d.zmtcdn.com/data/pictures/chains/8/16774318/a54deb9e4dbb79dd7c8091b30c642077_featured_v2.png",
      "photos_url": "https://www.zomato.com/new-york-city/otto-enoteca-pizzeria-greenwich-village/photos#tabtop",
      "menu_url": "https://www.zomato.com/new-york-city/otto-enoteca-pizzeria-greenwich-village/menu#tabtop",
      "events_url": "https://www.zomato.com/new-york-city/otto-enoteca-pizzeria-greenwich-village/events#tabtop",
      "user_rating": {
        "aggregate_rating": "3.7",
        "rating_text": "Very Good",
        "rating_color": "5BA829",
        "votes": "1046"
      },
      "has_online_delivery": "0",
      "is_delivering_now": "0",
      "deeplink": "zomato://r/16774318",
      "cuisines": "Cafe",
      "all_reviews_count": "15",
      "photo_count": "18",
      "phone_numbers": "(212) 228-2930",
      "photos": [
        {
          "id": "u_MjA5MjY1OTk5OT",
          "url": "https://b.zmtcdn.com/data/reviews_photos/c15/9eb13ceaf6e90129c276ce6ff980bc15_1435111695_640_640_thumb.JPG",
          "thumb_url": "https://b.zmtcdn.com/data/reviews_photos/c15/9eb13ceaf6e90129c276ce6ff980bc15_1435111695_200_thumb.JPG",
          "user": {
            "name": "John Doe",
            "zomato_handle": "John",
            "foodie_level": "Super Foodie",
            "foodie_level_num": "9",
            "foodie_color": "f58552",
            "profile_url": "https://www.zomato.com/john",
            "profile_deeplink": "zoma.to/u/1170245",
            "profile_image": "string"
          },
          "res_id": "16782899",
          "caption": "#awesome",
          "timestamp": "1435111770",
          "friendly_time": "3 months ago",
          "width": "640",
          "height": "640",
          "comments_count": "0",
          "likes_count": "0"
        }
      ],
      "all_reviews": [
        {
          "rating": "5",
          "review_text": "The best latte I've ever had. It tasted a little sweet",
          "id": "24127336",
          "rating_color": "305D02",
          "review_time_friendly": "2 months ago",
          "rating_text": "Insane!",
          "timestamp": "1435507367",
          "likes": "0",
          "user": {
            "name": "John Doe",
            "zomato_handle": "John",
            "foodie_level": "Super Foodie",
            "foodie_level_num": "9",
            "foodie_color": "f58552",
            "profile_url": "https://www.zomato.com/john",
            "profile_deeplink": "zoma.to/u/1170245",
            "profile_image": "string"
          },
          "comments_count": "0"
        }
      ]
    }
  ]
}
```

We are taking it even further by pulling out the population stats and spread of various races in the neighborhood. We will go to as deep as zips, counties and tracts to make the population stats as precise as possible. 

Get Area details such as City, County, Block, FIPS Code etc., from BroadbandMap API:
```
http://www.broadbandmap.gov/broadbandmap/census/block?latitude=#{self.location_lat}&longitude=#{self.location_lng}&format=json
```
All the available zip codes in 15 mile radius can be fetched from ZipCodes API:
```
https://www.zipcodeapi.com/rest/#{Rails.application.config.zip_code_key}/radius.json/<<Zip_Code>>/15/mile
```

We will also build a favorability matrix between population and cuisines (Ex. Asians prefer Chinese, Indian whereas Hispanics prefer Mexican, Spanish and Italian etc.). 

Census information can be pulled from US Census API, we can get the composition of various races in the area:
```
http://api.census.gov/data/2015/pdb/tract?get=County_name,State_name,NH_White_alone_CEN_2010,NH_Blk_alone_CEN_2010,Hispanic_CEN_2010,NH_AIAN_alone_CEN_2010,NH_Asian_alone_CEN_2010,Age5p_Hindi_ACSMOE_09_13,Age5p_Chinese_ACS_09_13,Males_CEN_2010,Females_CEN_2010,Tot_Population_CEN_2010&for=tract:*&in=state:#{self.fips_state}+county:#{self.fips_county}
```

Moreover, we will also pull out the reviews for each competing restaurant and put them under our DataMining and Analysis techniques to understand the emotions, sentiments of a particular review. We will also find good and bads of a restaurant based on this (Ex: Golden Dragon - Orange Chicken is heavenly, Lamb is good, Desserts are bad etc.).

Reviews can be pulled from Zomato, Google and Yelp:
```
https://developers.zomato.com/api/v2.1/reviews?res_id=#{self.zomato_restaurant_id}", accept: :json, 'user-key' => Rails.application.config.zomato_key
```

UNDERSTANDING THE REVIEWS AND RATINGS
-------------------------------------
Pulling the data from various sources is pretty straight-forward and clear, but analysing the data and storing them onto our database in the most efficient manner is what we need to work on. 

We need to understand and implement the best-in-industry standard techniques to analyse the reviews, ratings, review authors and trends (based on review dates). This involves natural language processing, spotting various parts of a speech i.e. nouns, adjectives etc.,

Also, we need to input a big set of reference data which includes all the nouns related to food and food industry such as Pizza, Burger, Rice, Pasta | Tables, Spoons, Plates | Staff, Chef, Manager etc.,

We need to make our algorithm identify these nouns in every sentence and understand the author’s opinions on it and also assess his emotions on a fixed scale.

For example:
Author says “Pizza is good” → Pizza - Positive 60% (Due to usage of good)
Author says “They have the best desserts in town” → Dessert - Positive 80% (Due to usage of Best)
Author says “Food is good but the staff are awful” → Food - Positive 60% and Staff - Negative 70%

In addition, we need to give confidence score as well as relevance score, this helps in ranking the statements while deciding the overall sentiment of the review.

We need to map all parts in a statement to a hierarchical structure.
Ex:

![alt tag](https://s10.postimg.org/dmv4n7e15/Screen_Shot_2017-04-23_at_01.40.52.png)

This needs to be as precise as possible. Instead of developing this from the roots, we can pull out various techniques and algorithms from papers and other sources. We can further develop this to specifically suit our food industry model.


AUTHORS
-------

**Manideep Bollu**

+ https://github.com/manideepbollu
+ http://manideepbollu.com

**Anil Kilari**

+ https://github.com/akilari
