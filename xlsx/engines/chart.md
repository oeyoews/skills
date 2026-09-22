# Chart Engine — Selection & Specs

> Load this file when the task needs charts. **Also read `engines/chart-templates.md`** for implementation code — always load both together.

---

## Decision: Native Excel Charts Only

This environment has **no image generation capability** — every chart is a native Excel chart
(`openpyxl.chart`). Never embed a chart as an image.

| Situation | Use |
|-----------|-----|
| User will interact with chart in Excel (resize, filter, update) | **Native Excel chart** (openpyxl.chart) |
| Publication-quality or complex visualization (heatmap, multi-axis) | **Native Excel chart** — approximate with the closest native type (bar/line/scatter) |
| Dashboard with multiple small charts | **Native Excel charts**, one per anchor cell |
| Simple bar/line/pie from sheet data | **Native Excel chart** |

---

## Chart Size & Placement

```python
CHART_SIZES = {
    'small': (12, 7),    # ~400x230px — inline with data
    'medium': (18, 10),  # ~600x330px — standard report chart
    'large': (24, 14),   # ~800x460px — full-width dashboard
}
```

Multiple charts on one sheet: each chart ≈ 15 rows tall + 2 rows gap. Calculate anchor positions to prevent overlap.

---

## Smart Chart Recommendation

When user doesn't specify chart type, auto-select:

| Data Pattern | Best Chart | Avoid |
|-------------|-----------|-------|
| Trend over time | Line | Pie |
| Category comparison (≤6) | Bar (vertical) | Pie |
| Category comparison (7-15) | Horizontal Bar | Vertical bar |
| Category comparison (>15) | Top 10 bar + "Others" | All-in-one |
| Part of whole (≤5 slices) | Pie / Donut | Bar |
| Part of whole (>8) | Horizontal Bar | Pie |
| Distribution | Histogram | Pie |
| Correlation | Scatter | Bar |
| Budget vs Actual | Clustered Bar + variance line | Pie |
| Mixed scales ($ + %) | Combo (bar + line) | Single axis |

### Auto-Detection from Headers

| Header patterns | Suggested chart |
|----------------|-----------------|
| Date, Month, Quarter, Year, 月, 季度, 年 | Line / Area |
| Category, Type, Product, Region, 类别, 产品 | Bar |
| Percentage, Share, %, 占比, 份额 | Pie / Donut |
| Budget + Actual, 预算 + 实际 | Clustered Bar |
| Revenue + Cost + Profit, 收入 + 成本 + 利润 | Stacked Bar / Combo |
| Growth, Change, Δ, 增长, 变化 | Line with markers |

---

## Critical Rules

1. **`titles_from_data=True`**: First row of data reference MUST contain text headers
2. **Cached Values**: Excel-native charts read cached cell values, so point them at cells that hold computed values (or at the source data range) — never at freshly written formulas, which have no cached value
3. **Hidden Data**: Set `chart.plot_visible_only = False` when chart data comes from hidden rows
4. **Chinese Font**: All chart titles and axis titles MUST go through `make_chart_title()` from `templates/base.py` — it bakes the CJK font into the chart's rich text so WPS and Office render identically
5. **Native charts only**: No image-based charts — this environment has no image generation capability

### Color Palette

Chart colors are derived from **`engines/design.md §9`**. Do NOT define independent colors.

```python
# Import from design tokens — single source of truth
# CHART_COLORS = [PRIMARY, ACCENT_POSITIVE, ACCENT_WARNING, ACCENT_NEGATIVE, NEUTRAL_600]
# Single series → PRIMARY only
# Two series → PRIMARY + ACCENT_POSITIVE
# Never exceed 5 colors
```

---

## Code Templates

For specific chart implementation code (bar, line, pie, scatter, combo), load `engines/chart-templates.md`.
