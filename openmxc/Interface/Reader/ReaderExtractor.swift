import WebKit

enum ReaderExtractor {
    /// Extracts the article content of the web view's current page as a
    /// compact JSON document, parsed into a `ReaderArticle`. Returns nil when
    /// the page has no meaningful article text.
    @MainActor
    static func extract(from webView: WKWebView) async -> ReaderArticle? {
        guard let url = webView.url,
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else { return nil }
        let result = try? await webView.evaluateJavaScript(extractionScript) as? String
        guard let json = result else { return nil }
        return ReaderArticle.parse(json: json, url: url)
    }

    /// Heuristic readability pass: picks the densest of article/main/[role=main]
    /// (falling back to body), then walks it collecting headings, paragraphs,
    /// quotes, lists, code, and images. Boilerplate containers are skipped and
    /// the output is capped so pathological pages stay cheap to render.
    static let extractionScript = #"""
        (function () {
            function cleanText(el) {
                return (el.innerText || el.textContent || '').replace(/\s+/g, ' ').trim();
            }
            var SKIP = { script:1, style:1, noscript:1, svg:1, nav:1, footer:1, header:1,
                         form:1, aside:1, button:1, iframe:1, select:1, textarea:1, canvas:1 };
            function pickRoot() {
                var best = document.body, bestScore = 0;
                var candidates = document.querySelectorAll('article, [role="main"], main');
                for (var i = 0; i < candidates.length; i++) {
                    var score = cleanText(candidates[i]).length;
                    if (score > bestScore) { bestScore = score; best = candidates[i]; }
                }
                return best;
            }
            var root = pickRoot();
            var blocks = [];
            var total = 0;
            var MAX_BLOCKS = 250;
            var MAX_CHARS = 100000;
            function push(block, length) {
                if (blocks.length >= MAX_BLOCKS || total > MAX_CHARS) return;
                blocks.push(block);
                total += length;
            }
            function imageURL(img) {
                var src = img.currentSrc || img.src || '';
                if (!src || src.indexOf('data:') === 0) return null;
                try { src = new URL(src, document.baseURI).href; } catch (e) { return null; }
                if (src.indexOf('http') !== 0) return null;
                if (img.naturalWidth && img.naturalWidth < 64) return null;
                return src;
            }
            function walk(el) {
                if (!el || !el.children) return;
                for (var i = 0; i < el.children.length; i++) {
                    if (blocks.length >= MAX_BLOCKS || total > MAX_CHARS) return;
                    var child = el.children[i];
                    var tag = child.tagName.toLowerCase();
                    if (SKIP[tag]) continue;
                    if (/^h[1-4]$/.test(tag)) {
                        var headingText = cleanText(child);
                        if (headingText) push({ type: 'heading', level: parseInt(tag.charAt(1), 10), text: headingText }, headingText.length);
                        continue;
                    }
                    if (tag === 'p') {
                        var paragraphText = cleanText(child);
                        if (paragraphText.length > 1) push({ type: 'paragraph', text: paragraphText }, paragraphText.length);
                        continue;
                    }
                    if (tag === 'blockquote') {
                        var quoteText = cleanText(child);
                        if (quoteText.length > 1) push({ type: 'quote', text: quoteText }, quoteText.length);
                        continue;
                    }
                    if (tag === 'pre') {
                        var codeText = (child.innerText || '').trim();
                        if (codeText) push({ type: 'code', text: codeText }, codeText.length);
                        continue;
                    }
                    if (tag === 'ul' || tag === 'ol') {
                        var items = [];
                        var listItems = child.querySelectorAll('li');
                        for (var j = 0; j < listItems.length && items.length < 50; j++) {
                            var itemText = cleanText(listItems[j]);
                            if (itemText) items.push(itemText);
                        }
                        if (items.length) push({ type: 'list', items: items }, items.join(' ').length);
                        continue;
                    }
                    if (tag === 'img') {
                        var directURL = imageURL(child);
                        if (directURL) {
                            var altText = (child.getAttribute('alt') || '').trim();
                            push({ type: 'image', url: directURL, alt: altText }, altText.length + directURL.length);
                        }
                        continue;
                    }
                    if (tag === 'figure') {
                        var figureImage = child.querySelector('img');
                        if (figureImage) {
                            var figureURL = imageURL(figureImage);
                            if (figureURL) {
                                var caption = child.querySelector('figcaption');
                                var captionText = caption ? cleanText(caption) : '';
                                var figureAlt = captionText || (figureImage.getAttribute('alt') || '').trim();
                                push({ type: 'image', url: figureURL, alt: figureAlt }, figureURL.length + figureAlt.length);
                                continue;
                            }
                        }
                        walk(child);
                        continue;
                    }
                    walk(child);
                }
            }
            walk(root);
            function meta(selector) {
                var el = document.querySelector(selector);
                return el ? (el.getAttribute('content') || '').trim() : '';
            }
            var title = meta('meta[property="og:title"]') || meta('meta[name="twitter:title"]');
            if (!title) {
                var firstHeading = root.querySelector('h1');
                title = firstHeading ? cleanText(firstHeading) : (document.title || '').trim();
            }
            var byline = meta('meta[name="author"]') || meta('meta[property="article:author"]');
            var siteName = meta('meta[property="og:site_name"]');
            return JSON.stringify({ title: title, byline: byline, siteName: siteName, blocks: blocks });
        })()
        """#
}
