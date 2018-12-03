<style>

.reveal .slideContent {
  font-size: 0.7em;
}

.reveal pre code {
  font-size: 0.8em;
}

.reveal h1 {
 display: block;
 font-size: 1.6em;
 font-weight: bold;
}

.reveal h2 {
 display: block;
 font-size: 1.2em;
 font-weight: bold;
}

</style>

Yet Another Next Word Guesser
========================================================
title: false
author: Pascal P.
date: 01-12-2018
transition: rotate
incremental: true
navigation: slide 
autosize: true
width: 1200
height: 1024
font-family: 'Helvetica'

Yet Another Next Word Guesser [やねをぐ]

- A word predictor using NLP in R
- Code available: https://github.com/pascal-p/cp
- This Presentation: https://rpubs.com/Pascal/cap_final_pres
- Demo App available: https://lacsap-ml.shinyapps.io/yanewogu/

Context: Coursera JHU, Capstone Project


Purpose 2/5
========================================================
type: section

- Build a language model based on a corpora provided by Swiftkey
- The corpora is composed of three sources
  - blogs
  - news and 
  - twitter
- Use the built language model (5-grams) to predict next word given some previous words (here 4 words).
- Build a web interactive application using R shiny, which given a sentence provides a set of prediction (possible next words)


Model 3/5
========================================================
type: section

- Built a 5-grams probabilistic language model using simple ("stupid") back-off algorithm, using R `quanteda` package.
- Used full corpora, after clean-up and created three sets: training (80%), test(10%) and development (10%).
- Background
  - A probabilistic model is based on the idea that in order to predict the next word, we only need a few previous words (Markov assumption).
  - In a 5-grams model, we relies on the four previous words to predict the fifth one.
  - Formally, we have a sequence of $N$ words $w_{1}^{n} = w_{1}..w_{n}$ and when we use a 5 grams model, we are making the following approximation:
$$
 \begin{aligned}
 P(w_{n}|w_{1}^{n-1}) \approx P(w_{n}|w_{n-1}^{n-4})
 \end{aligned}
$$
  where $P(w|h)$ is the probability of a word $w$ given some history (previous words), $h$.
  These probabilities are estimated using maximum likelihood estimation.
 - "Stupid" Back-off which was introduced uses relative frequencies (counts) to define a score (denoted $S$, not a probability):
$$
 \begin{aligned}
 S(w_{n}|w_{n-k+1}^{n-1})=\left\lbrace
 \begin{array}{l}
 \frac{C(w_{n-k+1}^{n})}{C(w_{n-k+1}^{n-1})}, \space if \space C(w_{n-k+1}^{n}) > 0 \\
 \alpha \times C(w_{n}|w_{n-k+2}^{n-1}), \space otherwise
 \end{array}
 \right.
 \end{aligned}
$$
  with a recommended value $\alpha=0.4$


Prediction Algorithm 4/5
========================================================
type: section

- We pre-computed all the scores from 5-grams down to uni-grams using previous equation (for "stupid Back-off") on our language model.
- All results were stored in data table (using R `data.table` package)
- We then pruned the results. All entries with a frequency count of less than 3 were removed. 
  - A trade-off between efficiency and the size of the data model.
- Our prediction need to first load the data model into memory (this takes a few seconds), once loaded and 
- Given the previous four words (context) from user input, the application re-actively starts a look-up in the 5-grams portion of the model
- If we find enough matching entries, we can return the result: 
  - top 5 entries with their score to chose from in decreasing order of score
- Otherwise if no match found or not enough matches (strictly less then 5), we do a look up in 4-grams portion of the model.
  - this process is repeated until we get our 5 predictions down to the uni-gram portion of the model.
- If there were no match at all, we then return the top 5 uni-grams (by relative frequency)
- Using benchmark provided (cf. reference section), we obtained:  

```
Overall top-3 score:     18.51 %
Overall top-1 precision: 13.93 %
Overall top-3 precision: 22.49 %
Average runtime:         15.11 msec
Number of predictions:   28464
Total memory used:       152.47 MB
```



Screenshot Demo App 5/5
========================================================
type: section

<br />
- Instructions on how to use the demonstration application can be found on the Shiny application itself, "About" tab.  
  Please check them if you need to.
<br />
- Example - prediction and score: <br />
<img src='./yanewoguPres.md-figure/prediction_ex.png' alt="Prediction example" style="width:100%;height:100%;border:0;float:left;">

*** 
<br />
- Example - loading the data model<br />
<img src='./yanewoguPres.md-figure/modal_for_loading_data_model.png' alt="Modal Dialog for loading data model" style="width:100%;height:100%;border:0;float:left;">



References
========================================================
type: section

- For a background in NLP, https://web.stanford.edu/~jurafsky/slp3/
- "Stupid" Back-off, https://www.aclweb.org/anthology/D07-1090.pdf, page 2
- R quanteda: Quantitative Analysis of Textual Data, https://quanteda.io/
- R data.table, https://rdrr.io/cran/data.table/
- benchmark for capstone project, https://github.com/hfoffani/dsci-benchmark 
