# Chart Templates — Implementation Code

> This file contains chart implementation code. **Read it together with `engines/chart.md`** whenever the task involves charts.

---

## Native Excel Charts (openpyxl.chart)

### Bar Chart
```python
from openpyxl.chart import BarChart, Reference
from templates.base import make_chart_title

chart = BarChart()
chart.type = "col"
chart.title = make_chart_title("Revenue by Product", 14)
chart.y_axis.title = make_chart_title("Revenue ($)", 10, bold=False, axis=True)
chart.x_axis.title = make_chart_title("Product", 10, bold=False)

data = Reference(ws, min_col=3, min_row=4, max_col=3, max_row=last_row)
cats = Reference(ws, min_col=2, min_row=5, max_row=last_row)

chart.add_data(data, titles_from_data=True)
chart.set_categories(cats)
chart.shape = 4
chart.width = 18
chart.height = 10

ws.add_chart(chart, "J4")
```

### Line Chart
```python
from openpyxl.chart import LineChart, Reference
from templates.base import make_chart_title

chart = LineChart()
chart.title = make_chart_title("Monthly Trend", 14)
chart.y_axis.title = make_chart_title("Amount", 10, bold=False, axis=True)
chart.style = 10

data = Reference(ws, min_col=3, max_col=5, min_row=4, max_row=last_row)
cats = Reference(ws, min_col=2, min_row=5, max_row=last_row)

chart.add_data(data, titles_from_data=True)
chart.set_categories(cats)
for series in chart.series:
    series.smooth = True

ws.add_chart(chart, "J4")
```

### Pie Chart
```python
from openpyxl.chart import PieChart, Reference
from openpyxl.chart.label import DataLabelList
from templates.base import make_chart_title

chart = PieChart()
chart.title = make_chart_title("Market Share", 14)

data = Reference(ws, min_col=3, min_row=4, max_row=last_row)
cats = Reference(ws, min_col=2, min_row=5, max_row=last_row)

chart.add_data(data, titles_from_data=True)
chart.set_categories(cats)

chart.dataLabels = DataLabelList()
chart.dataLabels.dLblPos = 'bestFit'
chart.dataLabels.showLeaderLines = True
chart.dataLabels.showCatName = True
chart.dataLabels.showPercent = True
chart.dataLabels.showVal = False

ws.add_chart(chart, "J4")
```

### Combo Chart (Bar + Line, dual axis)
```python
from openpyxl.chart import BarChart, LineChart, Reference
from templates.base import make_chart_title

bar = BarChart()
bar.add_data(Reference(ws, min_col=2, max_col=2, min_row=1, max_row=10), titles_from_data=True)
bar.title = make_chart_title("Revenue vs Growth", 14)
bar.y_axis.title = make_chart_title("Revenue ($)", 10, bold=False, axis=True)

line = LineChart()
line.add_data(Reference(ws, min_col=3, max_col=3, min_row=1, max_row=10), titles_from_data=True)
line.y_axis.title = make_chart_title("Growth %", 10, bold=False, axis=True)
line.y_axis.axId = 200

bar += line
ws.add_chart(bar, "E2")
```

---

## Smart Chart Recommend Function
```python
import pandas as pd

def recommend_chart(df, x_col, y_cols):
    if pd.api.types.is_datetime64_any_dtype(df[x_col]):
        return "line"
    n_categories = df[x_col].nunique()
    n_series = len(y_cols)
    if n_series == 1:
        vals = df[y_cols[0]]
        if vals.sum() > 95 and vals.sum() < 105:
            return "pie" if n_categories <= 5 else "bar_horizontal"
    if n_categories <= 6:
        return "bar_grouped" if n_series > 1 else "bar"
    elif n_categories <= 15:
        return "bar_horizontal"
    else:
        return "bar_top10"
```
