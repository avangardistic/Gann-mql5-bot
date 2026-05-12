//+------------------------------------------------------------------+
//|                                            GannBox.mq5           |
//|                      Gann Box Indicator for MT5                   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Hossein Parasteh"
#property link      "https://github.com/avangardistic"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 7
#property indicator_plots   7

//--- تنظیمات بافرها
#property indicator_label1  "Top Line"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGray
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#property indicator_label2  "Bottom Line"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrGray
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

#property indicator_label3  "Left Line"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrGray
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1

#property indicator_label4  "Right Line"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrGray
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1

#property indicator_label5  "Diagonal Up"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrWhite
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1

#property indicator_label6  "Diagonal Down"
#property indicator_type6   DRAW_LINE
#property indicator_color6  clrWhite
#property indicator_style6  STYLE_SOLID
#property indicator_width6  1

#property indicator_label7  "Gann Arc"
#property indicator_type7   DRAW_LINE
#property indicator_color7  clrDodgerBlue
#property indicator_style7  STYLE_SOLID
#property indicator_width7  1

//--- پارامترهای ورودی
input ENUM_TIMEFRAMES GannTimeframe = PERIOD_D1;  // Gann Timeframe
input int LineWidth = 1;                          // Line Width
input color BoxColor = clrGray;                   // Box Color
input color DiagonalsColor = clrWhite;            // Diagonals Color
input color CircleColor = clrDodgerBlue;          // Gann Circles Color
input int CircleTransparency = 150;               // Circle Transparency (0-255)

//--- بافرهای اندیکاتور
double TopLineBuffer[];
double BottomLineBuffer[];
double LeftLineBuffer[];
double RightLineBuffer[];
double DiagonalUpBuffer[];
double DiagonalDownBuffer[];
double GannArcBuffer[];

//--- متغیرهای سراسری
datetime lastBarTime = 0;
datetime cycleStartTime = 0;
datetime cycleEndTime = 0;
double cycleHigh = 0;
double cycleLow = DBL_MAX;
double cycleStartPrice = 0;
bool isNewCycle = false;
int cycleBars = 0;

//+------------------------------------------------------------------+
//| تابع مقداردهی اولیه                                               |
//+------------------------------------------------------------------+
int OnInit() {
   // تنظیم بافرها
   SetIndexBuffer(0, TopLineBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, BottomLineBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, LeftLineBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, RightLineBuffer, INDICATOR_DATA);
   SetIndexBuffer(4, DiagonalUpBuffer, INDICATOR_DATA);
   SetIndexBuffer(5, DiagonalDownBuffer, INDICATOR_DATA);
   SetIndexBuffer(6, GannArcBuffer, INDICATOR_DATA);
   
   // تنظیم پلات‌ها
   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(2, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(3, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(4, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(5, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(6, PLOT_DRAW_TYPE, DRAW_LINE);
   
   // تنظیم رنگ‌ها
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, BoxColor);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, BoxColor);
   PlotIndexSetInteger(2, PLOT_LINE_COLOR, BoxColor);
   PlotIndexSetInteger(3, PLOT_LINE_COLOR, BoxColor);
   PlotIndexSetInteger(4, PLOT_LINE_COLOR, DiagonalsColor);
   PlotIndexSetInteger(5, PLOT_LINE_COLOR, DiagonalsColor);
   PlotIndexSetInteger(6, PLOT_LINE_COLOR, CircleColor);
   
   // تنظیم ضخامت خطوط
   PlotIndexSetInteger(0, PLOT_LINE_WIDTH, LineWidth);
   PlotIndexSetInteger(1, PLOT_LINE_WIDTH, LineWidth);
   PlotIndexSetInteger(2, PLOT_LINE_WIDTH, LineWidth);
   PlotIndexSetInteger(3, PLOT_LINE_WIDTH, LineWidth);
   PlotIndexSetInteger(4, PLOT_LINE_WIDTH, LineWidth);
   PlotIndexSetInteger(5, PLOT_LINE_WIDTH, LineWidth);
   PlotIndexSetInteger(6, PLOT_LINE_WIDTH, LineWidth);
   
   IndicatorSetString(INDICATOR_SHORTNAME, "Gann Box (" + EnumToString(GannTimeframe) + ")");
   
   lastBarTime = 0;
   cycleStartTime = 0;
   cycleHigh = 0;
   cycleLow = DBL_MAX;
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| تابع اصلی محاسبات اندیکاتور                                        |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
   
   if(rates_total < 2) return(0);
   
   int start = prev_calculated > 0 ? prev_calculated - 1 : 1;
   
   for(int i = start; i < rates_total; i++) {
      // ریست کردن بافرها
      TopLineBuffer[i] = EMPTY_VALUE;
      BottomLineBuffer[i] = EMPTY_VALUE;
      LeftLineBuffer[i] = EMPTY_VALUE;
      RightLineBuffer[i] = EMPTY_VALUE;
      DiagonalUpBuffer[i] = EMPTY_VALUE;
      DiagonalDownBuffer[i] = EMPTY_VALUE;
      GannArcBuffer[i] = EMPTY_VALUE;
      
      // بررسی زمان بسته شدن شمع
      datetime currentTime = time[i];
      MqlDateTime dt;
      TimeToStruct(currentTime, dt);
      
      // تشخیص شروع چرخه جدید بر اساس تایم‌فریم
      bool isTimeToStart = false;
      
      if(GannTimeframe == PERIOD_D1) {
         if(dt.hour == 0 && dt.min == 0) isTimeToStart = true;
      }
      else if(GannTimeframe == PERIOD_H4) {
         if(dt.hour % 4 == 0 && dt.min == 0) isTimeToStart = true;
      }
      else if(GannTimeframe == PERIOD_H1) {
         if(dt.min == 0) isTimeToStart = true;
      }
      else if(GannTimeframe == PERIOD_W1) {
         if(dt.day_of_week == 1 && dt.hour == 0 && dt.min == 0) isTimeToStart = true;
      }
      else if(GannTimeframe == PERIOD_MN1) {
         if(dt.day == 1 && dt.hour == 0 && dt.min == 0) isTimeToStart = true;
      }
      
      if(isTimeToStart || cycleStartTime == 0) {
         // شروع چرخه جدید
         cycleStartTime = currentTime;
         cycleHigh = high[i];
         cycleLow = low[i];
         cycleStartPrice = open[i];
         isNewCycle = true;
         
         // محاسبه تعداد شمع‌های چرخه
         if(GannTimeframe == PERIOD_D1) cycleBars = 1440 / PeriodSeconds(PERIOD_CURRENT) * 60;
         else if(GannTimeframe == PERIOD_H4) cycleBars = 240 / PeriodSeconds(PERIOD_CURRENT) * 60;
         else if(GannTimeframe == PERIOD_H1) cycleBars = 60 / PeriodSeconds(PERIOD_CURRENT) * 60;
         else if(GannTimeframe == PERIOD_W1) cycleBars = 10080 / PeriodSeconds(PERIOD_CURRENT) * 60;
         else cycleBars = 100;
         
         if(cycleBars < 1) cycleBars = 1;
      }
      else {
         // به‌روزرسانی چرخه جاری
         if(high[i] > cycleHigh) cycleHigh = high[i];
         if(low[i] < cycleLow) cycleLow = low[i];
         isNewCycle = false;
      }
      
      // محاسبه موقعیت در چرخه
      int barsInCycle = i;
      for(int j = i; j >= 0 && time[j] >= cycleStartTime; j--) {
         barsInCycle = i - j;
         break;
      }
      
      // محاسبه پیشرفت چرخه (0 تا 1)
      double cycleProgress = (double)barsInCycle / cycleBars;
      if(cycleProgress > 1.0) cycleProgress = 1.0;
      
      // محاسبه خطوط Gann Box
      if(cycleProgress <= 1.0 && cycleStartTime > 0 && cycleHigh > 0 && cycleLow > 0) {
         double priceRange = cycleHigh - cycleLow;
         
         // خط بالای جعبه
         TopLineBuffer[i] = cycleHigh;
         
         // خط پایین جعبه
         BottomLineBuffer[i] = cycleLow;
         
         // خط عمودی چپ (در زمان شروع)
         if(barsInCycle == 0) {
            LeftLineBuffer[i] = cycleLow + priceRange * 0.5;
         }
         
         // خط عمودی راست (در زمان پایان)
         if(barsInCycle >= cycleBars - 1) {
            RightLineBuffer[i] = cycleLow + priceRange * 0.5;
         }
         
         // قطر صعودی (از پایین چپ به بالا راست)
         if(barsInCycle >= 0 && barsInCycle <= cycleBars) {
            DiagonalUpBuffer[i] = cycleLow + (priceRange * cycleProgress);
         }
         
         // قطر نزولی (از بالا چپ به پایین راست)
         if(barsInCycle >= 0 && barsInCycle <= cycleBars) {
            DiagonalDownBuffer[i] = cycleHigh - (priceRange * cycleProgress);
         }
         
         // قوس Gann (نیم‌دایره)
         double arcRadius = cycleBars * 0.5;
         if(arcRadius > 0) {
            double arcX = barsInCycle;
            double arcRatio = arcX / arcRadius;
            if(arcRatio <= 1.0 && arcRatio >= 0) {
               double arcY = MathSin(MathArccos(arcRatio)) * cycleBars;
               double arcNorm = arcY / cycleBars;
               GannArcBuffer[i] = cycleLow + (priceRange * arcNorm);
            }
         }
      }
   }
   
   return(rates_total);
}

//+------------------------------------------------------------------+
//| رسم اشیاء گرافیکی اضافی                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   ObjectsDeleteAll(0, "GannArc_");
}
