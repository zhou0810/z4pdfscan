import UIKit
import PDFKit

enum TextPDFService {

    // US Letter size
    private static let pageWidth: CGFloat = 612
    private static let pageHeight: CGFloat = 792
    private static let margin: CGFloat = 72

    static func generateTextPDF(from markdown: String) -> PDFDocument {
        let textRect = CGRect(
            x: margin,
            y: margin,
            width: pageWidth - margin * 2,
            height: pageHeight - margin * 2
        )

        let attributedString = parseMarkdown(markdown)

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let data = renderer.pdfData { context in
            let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
            var charIndex = 0
            let totalLength = attributedString.length

            while charIndex < totalLength {
                context.beginPage()

                let path = CGPath(rect: textRect, transform: nil)
                let range = CFRangeMake(charIndex, 0)
                let frame = CTFramesetterCreateFrame(framesetter, range, path, nil)

                let ctx = context.cgContext
                ctx.textMatrix = .identity
                ctx.translateBy(x: 0, y: pageHeight)
                ctx.scaleBy(x: 1, y: -1)

                CTFrameDraw(frame, ctx)

                let visibleRange = CTFrameGetVisibleStringRange(frame)
                charIndex += visibleRange.length

                if visibleRange.length == 0 {
                    break
                }
            }
        }

        return PDFDocument(data: data) ?? PDFDocument()
    }

    // MARK: - Markdown Parsing

    private static func parseMarkdown(_ markdown: String) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let lines = markdown.components(separatedBy: "\n")

        let bodyFont = UIFont.systemFont(ofSize: 12)
        let boldFont = UIFont.boldSystemFont(ofSize: 12)
        let italicFont = UIFont.italicSystemFont(ofSize: 12)
        let h1Font = UIFont.boldSystemFont(ofSize: 24)
        let h2Font = UIFont.boldSystemFont(ofSize: 20)
        let h3Font = UIFont.boldSystemFont(ofSize: 17)

        let bodyStyle = NSMutableParagraphStyle()
        bodyStyle.lineSpacing = bodyFont.pointSize * 0.4

        let listStyle = NSMutableParagraphStyle()
        listStyle.lineSpacing = bodyFont.pointSize * 0.4
        listStyle.firstLineHeadIndent = 20
        listStyle.headIndent = 20

        let headingStyle = NSMutableParagraphStyle()
        headingStyle.paragraphSpacingBefore = 8
        headingStyle.paragraphSpacing = 4

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                result.append(NSAttributedString(string: "\n"))
                continue
            }

            var styledLine: NSAttributedString

            if trimmed.hasPrefix("### ") {
                let text = String(trimmed.dropFirst(4))
                styledLine = NSAttributedString(string: text + "\n", attributes: [
                    .font: h3Font,
                    .paragraphStyle: headingStyle
                ])
            } else if trimmed.hasPrefix("## ") {
                let text = String(trimmed.dropFirst(3))
                styledLine = NSAttributedString(string: text + "\n", attributes: [
                    .font: h2Font,
                    .paragraphStyle: headingStyle
                ])
            } else if trimmed.hasPrefix("# ") {
                let text = String(trimmed.dropFirst(2))
                styledLine = NSAttributedString(string: text + "\n", attributes: [
                    .font: h1Font,
                    .paragraphStyle: headingStyle
                ])
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                let text = String(trimmed.dropFirst(2))
                let bulletText = "\u{2022} " + text + "\n"
                styledLine = applyInlineFormatting(bulletText, baseFont: bodyFont, boldFont: boldFont, italicFont: italicFont, paragraphStyle: listStyle)
            } else {
                let text = trimmed + "\n"
                styledLine = applyInlineFormatting(text, baseFont: bodyFont, boldFont: boldFont, italicFont: italicFont, paragraphStyle: bodyStyle)
            }

            result.append(styledLine)
        }

        return result
    }

    private static func applyInlineFormatting(
        _ text: String,
        baseFont: UIFont,
        boldFont: UIFont,
        italicFont: UIFont,
        paragraphStyle: NSParagraphStyle
    ) -> NSAttributedString {
        let result = NSMutableAttributedString(string: text, attributes: [
            .font: baseFont,
            .paragraphStyle: paragraphStyle
        ])

        // Bold: **text**
        applyPattern("\\*\\*(.+?)\\*\\*", in: result, font: boldFont)

        // Italic: *text* (but not **)
        applyPattern("(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)", in: result, font: italicFont)

        return result
    }

    private static func applyPattern(_ pattern: String, in attributedString: NSMutableAttributedString, font: UIFont) {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        let fullString = attributedString.string as NSString
        let matches = regex.matches(in: attributedString.string, range: NSRange(location: 0, length: fullString.length))

        // Apply in reverse to preserve ranges
        for match in matches.reversed() {
            let fullRange = match.range
            let contentRange = match.range(at: 1)
            let content = fullString.substring(with: contentRange)

            attributedString.replaceCharacters(in: fullRange, with: content)
            let newRange = NSRange(location: fullRange.location, length: content.count)
            attributedString.addAttribute(.font, value: font, range: newRange)
        }
    }
}
