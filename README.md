cryptobnb
W6D2

TO RUN:

1. > ganage-cli -i 1234

2. > truffle console --network development

3. > compile

4. > migrate --reset

5. > test

6. > node server

7. > open localhost:8000/index.html

Sorry, didn't have enough time to properly complete frontend and format everything. It has been 4-5 years since I've done any front end dev work :(

TO DO:

- I underestimated how much code frontend would need. I would redesign front end with some framework(react /angular) to make code more organized and readable.
- Use events for better user experience 
- Would implement paging for properties
- Haven't had a chance to deploy to test network and use events to track progress
- There are a few security bugs, especially with check in function where I call Mint and Approve functions of PropertyToken.

Solidity code: would move helper functions to a separate file?
Solidity tests could use some work + better coverage
