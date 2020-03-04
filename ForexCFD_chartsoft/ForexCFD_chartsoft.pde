//for getting datas from rest api
final String api_key = "YOUR-API-KEY";
final String accID = "YOUR-ACCOUNT-NUMBER";
String currency_pair = "USD_JPY";
String granularity = "M15";
String num_candles = "119";
int displayedCandles = int(num_candles);
//

//for shell func
StringList strout = new StringList();
StringList strerr = new StringList();
//for shell func


//for draw chart
double[] candle_sticks   = new double[120];
ArrayList<Float> opens  = new ArrayList();
ArrayList<Float> highs  = new ArrayList();
ArrayList<Float> lows   = new ArrayList();
ArrayList<Float> closes = new ArrayList();
float price_per_px, center;

final int delay_time = 50;
boolean server_stat;
boolean bigBid = false;
String instrument;
float bid, ask, spread, ltp, balance;
ArrayList<Float> price_history = new ArrayList();
ArrayList<String> time_history = new ArrayList<String>();
String time;
float lot;
int lot_size = 100000;
int leverage = 100;
int second, minute, hour, day;
int lowestInit = 100000000;

void setup() {
  size(1900, 1010);
  getCandles();
  drawLayout();
}


void getCandles() {
  int i, j;
  String urls = "curl -H \"Authorization: Bearer " + api_key + "\" \"" + "https://api-fxpractice.oanda.com/v3/accounts/" + accID + "/instruments/" + currency_pair + "/candles?granularity=" + granularity + "&count=" + num_candles + "\"";
  String outFile = " > ohlc.json";
  String ohlc_data = "ohlc.json";
  String getOHLC = urls + outFile;
  JSONArray candles;
  JSONObject mid, tmp;
  float open, high, low, close;
  shell(strout, strerr, getOHLC);
  JSONObject candle_datas = loadJSONObject(ohlc_data);
  candles = candle_datas.getJSONArray("candles");
  for (i = candles.size() - 1, j = 0; i >= 0; i--, j++) {
    tmp = candles.getJSONObject(i);
    mid = tmp.getJSONObject("mid");
    open  = mid.getFloat("o");
    high  = mid.getFloat("h");
    low   = mid.getFloat("l");
    close = mid.getFloat("c");

    opens.add(j, open);
    highs.add(j, high);
    lows.add(j, low);
    closes.add(j, close);
  }
}

//main function
void draw() {
  second = second();
  minute = minute();
  hour = hour();
  day = day();
  getMarketData();
  drawLayout();
  drawMarketData();
  delay(delay_time);
}

String[] times = {"M1", "M5", "M15", "M30", "H1", "H4", "H12", "D", "W", "M"};
String[] insts = {"USDJPY", "EURUSD", "EURJPY", "GBPUSD", "GBPJPY", "WTI", "BRENT", "XAUUSD", "XCUUSD", "DOW", "NSDQ", "S&P", "JPN225", "US30B"};
String[] instsN = {"USD_JPY", "EUR_USD", "EUR_JPY", "GBP_USD", "GBP_JPY", "WTICO_USD", "BCO_USD", "XAU_USD", "XCU_USD", "US30_USD", "NAS100_USD", "SPX500_USD", "JP225_USD", "USB30Y_USD"};

void drawLayout() {
  background(30, 30, 30);
  fill(255);
  textAlign(RIGHT, CENTER);
  textSize(30);
  text(granularity, 1700, 25);

  if (server_stat) {
    text("Market open", 1600, 25);
  } else {
    text("Market closed", 1600, 25);
  }
  
  if(time != null){ 
  text(time.substring(0, 10) + " " + time.substring(11, 19) + "(UTC-3)", 1350, 25); 
  }

  textAlign(LEFT, CENTER);
  if (instrument != null) {
    text(instrument, 10, 25);
  }

  //time display
  stroke(255);
  textAlign(CENTER, CENTER);
  textSize(20);
  
  for(int i = 1; i <= times.length; i++){
    line(i * 50 + 300, 0, i * 50 + 300, 50);
    text(times[i - 1], i * 50 + 325, 25);
  }
  
  line((times.length + 1) * 50 + 300, 0, (times.length + 1) * 50 + 300, 50);
  
  //instruments display
  textSize(15);
  for (int i = 1; i <= insts.length; i++) {
    line(i * 80, lowestY, i * 80, height);
    text(insts[i - 1], i * 80 - 40, 955);
  }
  //bigbid?
  line(1720, lowestY, 1720, height);
  text("BIG", 1745, 955);
  text("bid", 1745, 975);

  //big bid
  if (bigBid) {
    textAlign(CENTER, CENTER);
    textSize(300);
    fill(255, 255, 255, 200);
    text(bid, width/2 - 100, height/2);
  }
}

//get bid, ask, ltp, timestamp from rest api(oanda.com)
void getMarketData() {
  JSONObject market_data;
  String urls = "curl -H \"Authorization: Bearer " + api_key + "\" \"" + "https://api-fxpractice.oanda.com/v3/accounts/" + accID + "/pricing?instruments=" + currency_pair + "\"";
  String outFile = " > ticker.json" ;
  String getPrice = urls + outFile;
  String ticker = "ticker.json";  // file name of ticker data

  shell(strout, strerr, getPrice);
  market_data = loadJSONObject(ticker);
  JSONArray prices = market_data.getJSONArray("prices");


  //get  time, bid, ask, server stat from json file
  for (int i = 0; i < prices.size(); i++) {
    JSONObject tmp = prices.getJSONObject(i);
    time = tmp.getString("time");
    JSONArray bids = tmp.getJSONArray("bids");
    JSONArray asks = tmp.getJSONArray("asks");

    //get bid, ask
    for (int j = 0; j < bids.size(); j++) {
      JSONObject bidsary = bids.getJSONObject(j);
      JSONObject asksary = asks.getJSONObject(j);
      bid = bidsary.getFloat("price");
      ask = asksary.getFloat("price");
    }

    server_stat = tmp.getBoolean("tradeable");
    instrument = tmp.getString("instrument");
  }

  ltp = (bid + ask) / 2;
  spread = ask - bid;

  opens.set(0, closes.get(1));
  closes.set(0, bid);

  if (highs.get(0) <= bid) {
    highs.set(0, bid);
  }
  if (lows.get(0) >= bid) {
    lows.set(0, bid);
  }

  //create new candle stick when minute changed
  if (isRenewCandle()) {
    opens.add(0, 0.0);
    closes.add(0, bid);
    opens.set(0, closes.get(1));
    highs.add(0, 0.0);
    lows.add(0, 10000000.0);

    if (highs.get(0) <= bid) {
      highs.set(0, bid);
    }
    if (lows.get(0) >= bid) {
      lows.set(0, bid);
    }

    //remove oldest candle stick
    opens.remove(displayedCandles);
    highs.remove(displayedCandles);
    lows.remove(displayedCandles);
    closes.remove(displayedCandles);
  }

  price_history.add(0, ltp);
  time_history.add(0, time.substring(11, 22));
}

void drawMarketData() {
  drawBidAskSpreadEtc();
  drawChart();
}

void drawBidAskSpreadEtc() {
  textSize(20);
  textAlign(RIGHT, TOP);
}

//draw and calc stats and each position stat
int offset = 50;
float lowestY;

void drawChart() {
  float nowX = 1750;
  float oY, hY, lY, cY;  //distance from height(px)
  //search highest and lowest price in a chart
  lowest = lowestInit;
  highest = 0;
  for (int i = 0; i < displayedCandles; i++) {
    if (highs.get(i) >= highest) {
      highest = highs.get(i);
    }
    if (lows.get(i) <= lowest) {
      lowest = lows.get(i);
    }
  }
  getPriceHeightPerPx();
  float bidY = ((highest - bid) / price_per_px) + offset;
  float askY = ((highest - ask) / price_per_px) + offset;
  float highestY = ((highest - highest) / price_per_px) + offset;
  lowestY = ((highest - lowest) / price_per_px) + offset;
  stroke(230);
  line(1770, 0, 1770, height);
  line(0, highestY, 1770, highestY);
  line(0, lowestY, 1770, lowestY);
  stroke(30, 30, 30);
  fill(255);
  textAlign(LEFT, CENTER);
  text(highest, 1770, highestY);
  text(lowest, 1770, lowestY);  
  drawPrice(highest, lowest);
  rectMode(CORNER);
  //when askY bigger than 165, draw ask line and price
  if (askY > offset + 5) {
    fill(230, 0, 0);
    noStroke();
    rect(1775, askY-11.5, 120, 23);
    fill(0);
    text(ask, 1775, askY);
    stroke(200, 0, 0);
    line(0, askY, 1770, askY);
  }
  noStroke();
  fill(150, 150, 150);
  rect(1775, bidY-11.5, 120, 23);
  fill(0);
  text(bid, 1775, bidY);
  stroke(128);
  line(0, bidY, 1770, bidY);

  for (int i = 0; i < displayedCandles; i++) {
    //get distance(px) from Y = 0(each candle)
    oY = ((highest - opens.get(i)) / price_per_px) + offset;
    hY = ((highest - highs.get(i))/ price_per_px) + offset;
    lY = ((highest - lows.get(i)) / price_per_px) + offset;
    cY = ((highest - closes.get(i) ) / price_per_px) + offset;
    if (opens.get(i) > closes.get(i)) {
      fill(255);
    } else {
      fill(30, 30, 30);
    }

    rectMode(CORNERS);
    stroke(31, 255, 32);
    line(nowX + 5.55, hY, nowX + 5.55, lY);
    rect(nowX, oY, nowX + 10, cY);
    nowX -= 15;
  }
  //textSize(10);
  textAlign(LEFT, CENTER);
  rectMode(CORNER);
}

float highest = 0, lowest = lowestInit;

void getPriceHeightPerPx() {  
  float price_range;

  for (int i = 0; i < displayedCandles; i++) {
    if (highs.get(i) >= highest) {
      highest = highs.get(i);
    }
    if (lows.get(i) <= lowest) {
      lowest = lows.get(i);
    }
  }

  price_range  = highest - lowest;
  price_range  = float(round(price_range * pow(10, 3))) / pow(10, 3);
  price_per_px = price_range / width;
  price_per_px *= 2.15;
  center = (highest + lowest) / 2;
}


boolean isRenewCandle() {
  if (granularity == "M1") {
    if (minute != minute()) {
      return true;
    }
  } else if (granularity == "M5") {
    if (minute != minute() && minute() % 5 == 0) {
      return true;
    }
  } else if (granularity == "M15") {
    if (minute != minute() && minute() % 15 == 0) {
      return true;
    }
  } else if (granularity == "M30") {
    if (minute != minute() && minute() % 30 == 0) {
      return true;
    }
  } else if (granularity == "H1") {
    if (hour != hour()) {
      return true;
    }
  } else if (granularity == "H4") {
    if (hour != hour() && hour() % 4 == 0) {
      return true;
    }
  } else if (granularity == "H12") {
    if (hour != hour() && hour() % 12 == 0) {
      return true;
    }
  } else if (granularity == "D") {
    if (day != day()) {
      return true;
    }
  } else if (granularity == "W") {
    if (day != day() && zll(year(), month(), day()) == 1) {
      return true;
    }
  } else if (granularity == "M") {
    if (day != day() && day() == 1){
      return true;
    }
  }
  return false;
}

int zll(int y, int m, int d) {
  if (m < 3) {
    y --;
    m += 12;
  }
  return( y + y / 4 - y / 100 + y / 400 + (13 * m + 8) / 5 + d) % 7;
}


void drawPrice(float highest, float lowest) {
  float center  = (lowest + highest) / 2;
  float oneQ    = (lowest + center)  / 2;
  float thrQ    = (center + highest) / 2;
  float oneE    = (lowest + oneQ)    / 2;
  float thrE    = (oneQ   + center)  / 2;
  float fifE    = (center + thrQ)    / 2;
  float sevE    = (thrQ + highest)   / 2;

  float centerY = ((highest - center) / price_per_px) + offset;
  float oneQY   = ((highest - oneQ)   / price_per_px) + offset;
  float thrQY   = ((highest - thrQ)   / price_per_px) + offset;
  float oneEY   = ((highest - oneE)   / price_per_px) + offset;
  float thrEY   = ((highest - thrE)   / price_per_px) + offset;
  float fifEY   = ((highest - fifE)   / price_per_px) + offset;
  float sevEY   = ((highest - sevE)   / price_per_px) + offset;

  float[] pricesY = {oneEY, oneQY, thrEY, centerY, fifEY, thrQY, sevEY};  
  float[] prices =  {oneE, oneQ, thrE, center, fifE, thrQ, sevE};

  for (int i = 0; i < prices.length; i++) {
    text(prices[i], 1775, pricesY[i]);
    stroke(255);
    line(1770, pricesY[i], 1775, pricesY[i]);
  }
}

void clearArraylist() {
  opens.clear();
  highs.clear();
  lows.clear();
  closes.clear();
}

void mousePressed() {
  for (int i = 0; i < times.length; i++) {
    if (mouseX > i * 50 + 350 && mouseX < i * 50 + 400 && mouseY > 0 && mouseY < 50) {
      granularity = times[i];
      clearArraylist();
      setup();
    }
  }

  for (int i = 0; i < insts.length; i++) {
    if (mouseX > i * 80 && mouseX < i * 80 + 80 && mouseY > lowestY && mouseY < height) {
      currency_pair = instsN[i];
      clearArraylist();
      setup();
    }
  }
  if (mouseX > 1720 && mouseX < 1770 && mouseY > lowest && mouseY < height) {
    if (bigBid == true) {
      bigBid = false;
    } else {
      bigBid = true;
    }
  }
}
