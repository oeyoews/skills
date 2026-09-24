# docx-js Advanced Features

Advanced API for complex document scenarios. Load this when creating documents with TOC, cover pages, footnotes, multi-section layouts, or post-processing needs.

## Table of Contents (TOC)

**→ See `references/toc.md` for the complete TOC reference** (3-step process, code examples, page numbering, common bugs, checklist).

## Cover Page Design (Vertical Centering)

Use large `spacing.before` to push content down for visual centering:

```js
// Approximate vertical center on A4:
// Total printable height ≈ 14000 twips
// For title at ~40% from top: before = 5600
const coverSection = {
  properties: {
    page: { /* standard A4 */ },
    // No headers/footers on cover page
  },
  children: [
    new Paragraph({ spacing: { before: 5600 } }), // spacer
    new Paragraph({
      alignment: AlignmentType.CENTER,
      children: [new TextRun({
        text: title,
        font: { ascii: 'Calibri', eastAsia: 'SimHei' },
        size: 52, bold: true, color: palette.primary,
      })],
    }),
    // ... subtitle, author, date
  ],
};
```

For multi-section documents, put the cover in its own section so it can have different headers/footers.

## Footnotes

```js
const { FootnoteReferenceRun, Footnote } = require('docx');

const doc = new Document({
  footnotes: {
    1: { children: [new Paragraph({ children: [new TextRun({ text: 'Smith, J. (2024). Research Methods. Academic Press, pp. 45-67.', size: 18 })] })] },
    2: { children: [new Paragraph({ children: [new TextRun({ text: 'Zhang, W. (2023). \u201c数据分析方法研究\u201d. 科学通报, 68(12), 1234-1250.', size: 18 })] })] },
  },
  sections: [{
    children: [
      new Paragraph({
        children: [
          new TextRun({ text: 'According to recent studies' }),
          new FootnoteReferenceRun(1), // superscript [1]
          new TextRun({ text: ', data analysis methods have evolved' }),
          new FootnoteReferenceRun(2), // superscript [2]
          new TextRun({ text: '.' }),
        ],
      }),
    ],
  }],
});
```

### Academic Reference Pattern

For sequential references [1][2][3]..., pre-define all footnotes in the `footnotes` object with numeric keys, then reference them inline with `FootnoteReferenceRun(n)`.

## keepNext — Element Binding

Prevent page breaks between related elements:

```js
// Heading stays with next paragraph
new Paragraph({
  heading: HeadingLevel.HEADING_2,
  keepNext: true, // don't break after this
  children: [new TextRun({ text: 'Table 1: Results' })],
})
// Table immediately follows on same page

// Caption stays with its table
new Paragraph({
  keepNext: true,
  alignment: AlignmentType.CENTER,
  children: [new TextRun({ text: 'Table 1: Results', italics: true, size: 20 })],
})
// Table paragraph follows
```

Use `keepNext: true` for:
- Heading → first paragraph of section
- Table caption → table
- "Table X" label → table

## Page Break Rules

Follow the document type strategy defined in SOUL.md Rule 1.

**Structural breaks (always):**
- Cover page → TOC
- TOC → main content
- Main content → back cover

**Content breaks (by document type):**
- Academic / teaching → `new Paragraph({ children: [new PageBreak()] })` before each H1 chapter
- Business report → PageBreak before each H1; H2 flows naturally
- Resume / contract / letter → No content page breaks
- Short article → No content page breaks

**Anti-tear (mandatory):**
```js
// Heading stays with next paragraph
new Paragraph({
  heading: HeadingLevel.HEADING_1,
  keepNext: true,
  children: [new TextRun('Chapter Title')],
})

// Table caption stays with table
new Paragraph({
  keepNext: true,
  children: [new TextRun({ text: 'Table 1: Summary', italics: true })],
})

// Image caption stays with image
new Paragraph({
  keepNext: true,
  children: [new TextRun({ text: 'Figure 1: Architecture', italics: true })],
})
```

**Never:**
- PageBreak inside tables
- PageBreak as standalone element (must be inside Paragraph)
- PageBreak at the END of the last section (causes blank page)

```js
// Correct: page break between cover and TOC
new Paragraph({ children: [new PageBreak()] })
```

## Quotes Escaping in JS Strings

**⚠️⚠️⚠️ CRITICAL — #1 MOST COMMON BUG ⚠️⚠️⚠️**

The hazard is **any quote character that matches the literal's delimiter**. All code in this skill
uses **single-quote** string literals, so the dangerous character is the ASCII apostrophe `'`:

- ASCII `'` inside copy is the real risk — Chinese copy regularly carries apostrophes from English
  words (`It's`, `don't`, `Agent's`) and from quoted English terms
- ASCII `"` inside copy is **safe** under single quotes and needs no escaping
- Full-width Chinese quotes `“ ”` `‘ ’` (U+201C/U+201D, U+2018/U+2019) are **not** JS delimiters.
  They never break syntax and can be written directly — no Unicode escaping is required for them

| Character | Handling under the single-quote convention |
|-----------|---------------------------------------------|
| `“` `”` U+201C/U+201D | Write directly — never a syntax problem |
| `‘` `’` U+2018/U+2019 | Write directly — never a syntax problem |
| `"` U+0022 | Safe inside `'...'` — write it directly |
| `'` U+0027 | Must be escaped (`\'`), or the literal switched to `"..."` / a template literal |

```js
// ❌ WRONG — bare ASCII apostrophe inside a single-quoted literal: SyntaxError
new TextRun({ text: 'It's a test' })
new TextRun({ text: 'Agent 的 don\'t 问题' })

// ❌ WRONG — delimiter collision: the ASCII quotes terminate the literal early
content.push(para("2025年四个季度行业增速呈现"前低后高"的态势。在"618"大促、"双11""双12"活动拉动下增长显著。"));
new TextRun({ text: "他说"你好"" })

// ✅ CORRECT — ASCII double quotes are safe under single quotes
new TextRun({ text: 'He said "hello"' })
new TextRun({ text: '行业正从"手写 Prompt"走向平台化工程' })

// ✅ CORRECT — copy containing an apostrophe: switch delimiter, escape, or use a template literal
new TextRun({ text: "It's a test" })
new TextRun({ text: 'It\'s a test' })
new TextRun({ text: `It's a test` })

// ✅ CORRECT — full-width Chinese quotes need no escaping at all
new TextRun({ text: '他说“你好”' })
new TextRun({ text: '2025年四个季度行业增速呈现“前低后高”的态势。' })
```

## Multi-Section Documents

Different headers/footers per section:

```js
const doc = new Document({
  sections: [
    {
      // Section 1: Cover — no header/footer
      properties: { page: { /* ... */ } },
      children: coverChildren,
    },
    {
      // Section 2: Front matter — Roman page numbers
      properties: {
        type: SectionType.NEXT_PAGE,
        page: {
          /* size, margin... */
          pageNumbers: { start: 1, formatType: NumberFormat.UPPER_ROMAN },
        },
      },
      headers: { default: new Header({ children: [] }) },
      footers: {
        default: new Footer({
          children: [new Paragraph({
            alignment: AlignmentType.CENTER,
            children: [new TextRun({ children: [PageNumber.CURRENT], size: 18 })],
          })],
        }),
      },
      children: tocAndAbstract,
    },
    {
      // Section 3: Main content — Arabic page numbers
      properties: {
        type: SectionType.NEXT_PAGE,
        page: {
          /* size, margin... */
          pageNumbers: { start: 1, formatType: NumberFormat.DECIMAL },
        },
      },
      headers: {
        default: new Header({
          children: [new Paragraph({
            alignment: AlignmentType.CENTER,
            children: [new TextRun({ text: docTitle, size: 18, color: '888888' })],
          })],
        }),
      },
      footers: { default: footerWithPageNumbers },
      children: mainContent,
    },
  ],
});
```

## Converting DOCX to PDF / Images

> **Not available in this environment.** There is no DOCX→PDF engine installed and no way to install
> one, so PDF export and rendered previews cannot be produced here. Deliver the `.docx` itself and
> tell the user to export or print to PDF from their own Office/WPS install (Word's "Save as PDF"
> keeps TOC fields and pagination most faithfully).

> **TOC note (still applies):** if the document has a TOC, tell the user to open it in Word, update
> fields (Ctrl+A → F9), and save — page numbers only fill in once a word processor recalculates them.
