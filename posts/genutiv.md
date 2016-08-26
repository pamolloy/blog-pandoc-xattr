
*For further technical information check my [GitHub repository](https://github.com/pamolloy/Genutiv).*

This project aims to test the accuracy of patterns commonly cited in educational literature and then independently find the most accurate patterns. This process requires an initial collection of German nouns and their corresponding gender.

## Data sources ##
The most accessible source of nouns is the [German Wiktionary](http://de.wiktionary.org), which consists of 197,663 articles in 200 languages, of which 90,738 are German (see: [Wiktionary Sprachenübersicht](http://de.wiktionary.org/wiki/Wiktionary:Statistik/Sprachenübersicht)).

An excellent alternative source for German nouns is the cooperative online translation platform, [dict.cc](http://www.dict.cc/?s=about%3a). In addition to an extensive database that includes over 850,000 German-English translations, *dict.cc* has made their database accessible for download (see: [Request the translation database of dict.cc](http://www1.dict.cc/translation_file_request.php?l=e)). Once the database is downloaded it can be easily accessed with [dict2](http://students.mimuw.edu.pl/~lc235951/dict/index.html), a dictionary viewing application for GNU/Linux with GTK+.

Alternatively, a 1975 study by Gehard Angst developed a list of 2,162 simple German nouns.[^Augst]

### Wiktionary ###
The majority of the information contained within each Wiktionary article is easily accessible through the [MediaWiki API](http://de.wiktionary.org/w/api.php) used by Wiktionary. Genutiv uses [python-wikitools](http://code.google.com/p/python-wikitools) to interact with that API. These tools allow Genutiv to quickly return a list of pages within each category. For example, the following commands issued into the interpreter will return a list containing unicode strings representing the title of each member of the [Substantiv (Deutsch)](http://de.wiktionary.org/wiki/Kategorie:Substantiv_(Deutsch)) category.

```
>>> import wikitools
>>> url = wikitools.wiki.Wiki('http://de.wiktionary.org/w/api.php')
>>> substantiv = wikitools.category.Category(url, title='Substantiv (Deutsch)')
>>> nouns = substantiv.getAllMembers(titleonly=True)
>>> len(nouns)
36228
```

#### Categories ####
The _Substantiv (Deutsch)_ category consists of 36,217 pages that each contain at least one German noun, its gender, a description and further grammatical information. The discrepancy with the total in the previous example results from the fact that the _wikitools_ `getAllMembers` method includes parent and child categories by default when returning members. Unfortunately, _wikitools_ does not provide access to the `cmtype` parameter of the `list=categorymembers` module, which can be assigned to `page` in order to ignore those subcategories and files.

Unfortunately, the _Substantiv (Deutsch)_ category contains [proper nouns](http://en.wikipedia.org/wiki/Proper_noun), regional and antiquated nouns, and words borrowed from other languages.[^select] To exclude these types of nouns Genutiv takes advantage of preexisting categories to filter out nouns from the list containing the 36,217 pages in _Substantiv (Deutsch)_. Removing the nouns within the following categories results in a list containing 28,991 nouns, which is nearly 20% smaller than the original.[^page]

| Category | Pages | Parents
|-|-:|-
| [Eigenname (Deutsch)](http://de.wiktionary.org/wiki/Kategorie:Eigenname_(Deutsch)) | 288 | Substantiv (Deutsch)
| [Nachname (Deutsch)](http://de.wiktionary.org/wiki/Kategorie:Nachname_(Deutsch)) | 472 | Substantiv (Deutsch)
| [Vorname (Deutsch)](http://de.wiktionary.org/wiki/Kategorie:Vorname_(Deutsch)) | 1175 | Substantiv (Deutsch)
| [Toponym (Deutsch)](http://de.wiktionary.org/wiki/Kategorie:Toponym_(Deutsch)) | 3133 | Substantiv (Deutsch)
| [Substantive (Althochdeutsch)](http://de.wiktionary.org/wiki/Kategorie:Substantiv_(Althochdeutsch)) | 2 | Substantiv (Deutsch)
| [Substantive (Mittelhochdeutsch)](http://de.wiktionary.org/wiki/Kategorie:Substantiv_(Mittelhochdeutsch)) | 0 | Substantiv (Deutsch)
| [Substantive (Plattdeutsch)](http://de.wiktionary.org/wiki/Kategorie:Substantiv_(Plattdeutsch)) | 63 | Substantiv (Deutsch)
| [Fremdwort](http://de.wiktionary.org/wiki/Kategorie:Fremdwort) | 2093 | Deutsch

#### Gender ####
Unfortunately, the gender of each noun is buried in [wiki markup](http://en.wikipedia.org/wiki/Help:Wiki_markup), which the MediaWiki software converts to HTML. Initially, Genutiv used urllib2, Beautiful Soup and regular expressions to obtain the gender of each noun. The script downloaded the source code of the article corresponding to each noun and searched each line for an `<em>` tag with a `title` attribute and then processed the value (i.e. `Maskulinum`, `Femininum`, `Neutrum`). The trial run of this script removed 149 pages from the dictionary, which contained at least one number, dash or semi-colon. Of the remaining collection, 359 nouns did not match a gender and similarly not passed on.

A newer version of Genutiv took advantage of the `prop` module within the MediaWiki API, which can retrieve a series of properties for each page, including a list of templates. Genutiv would check the list of templates returned for each page and assign the gender based on whether it found a masculine, feminine or neuter template (i.e. [`{{ "{{m"}}}}`](http://de.wiktionary.org/wiki/Vorlage:f), [`{{ "{{f"}}}}`](http://de.wiktionary.org/wiki/Vorlage:m) or [`{{ "{{n"}}}}`](http://de.wiktionary.org/wiki/Vorlage:n)). The following test function accomplishes this task:

```
def gender(self, nouns):
    """Use MediaWiki API prop module to find relevant gender templates and
     assign gender to corresponding value"""

    for noun in nouns:
        page = wikitools.page.Page(self.site, title=noun)
        templates = page.getTemplates()

        for template in templates: #TODO(PM) Account for{{ "{{mf"}}}}
            if template == u'Vorlage:f':
                nouns[page.title] = "Femininum"
                break
            elif template == u'Vorlage:m':
                nouns[page.title] = "Maskulinum"
                break
            elif template == u'Vorlage:n':
                nouns[page.title] = "Neutrum"
                break

    return nouns
```

Unfortunately, this process leads to a large number of incorrect assignments. The order of the templates in the list  generated by wiki-tools does not correspond to their location on the page. Instead, they are sorted alphabetically with case sensitivity. Since the aforementioned gender templates often appear more than once on a page it can be difficult to determine which template accurately reflects the gender of the noun. For example, if the page corresponding to a masculine noun contains a `{{ "{{f"}}}}`, the noun will be assigned a feminine gender. This process is further complicated by the fact that it is nearly impossible to determine the genders of nouns with more than one definition (e.g. [Golf](http://de.wiktionary.org/wiki/Golf)). A quick comparison of the `prop` method with a list generated on September 23, 2011 revealed 26,706 nouns were assigned the same gender, but 5,141 nouns were assigned a different gender. Last, but certainly not least, there may not be a noticeable performance difference between the crawling method and the `prop` method.

### Source distortions ###
Although Wiktionary and dict.cc provide verbose sources of information they also distort the assessment of a pattern's accuracy with the inclusion of a large number of foreign proper nouns and compound nouns.

German compound nouns always take the gender and plural ending of the last noun in the compound. For example, the German feminine nouns [Galgenfrist](http://www.dict.cc/?s=Galgenfrist) and [Frist](http://www.dict.cc/?s=Frist) can both be counted as exceptions to the ending [`-ist`](/genutiv/ist/), which typically denotes a masculine noun. However, when a student is learning the gender of these nouns she only needs to learn the gender of *Frist*, since *Galgenfrist* shares the same gender. Therefore, counting these nouns as two exceptions distorts the accuracy of a pattern to predict the gender of a noun.

Additionally, there is a small number of German nouns that have dual gender. These nouns are spelled identically, but have different genders and definitions (e.g. [Band](http://de.wiktionary.org/wiki/Band)).

These distortions are apparent in the atypical distribution of gender within the Wiktionary collection (see: [Gender distribution](/blog/2011/08/16/gender#distribution)). The first version of _Genutiv_ returned 34,719 nouns with the following distribution: 12,087 (35%) masculine, 12,948 (37%) feminine and 9,684 (28%) neuter. This represents a significantly more even distribution than is commonly accepted. Notably, there are more feminine nouns than masculine, which is contrary to previous studies.

Another notable, but less prevalent, distortion is the result of user errors. For example, the first analysis of Wiktionary nouns revealed that 99.1% of the 213 nouns ending in [`-tät`](/genutiv/tät/) are feminine nouns, with two exceptions: [Sozialität](http://www.dict.cc/?s=Sozialität) and [Sprachloyalität](http://www.dict.cc/?s=Sprachloyalität). On Wiktionary those nouns were listed as masculine and neuter.[^taet] Both of these errors existed since the articles were created December 30, 2006 and March 2, 2008 respectively. Once these corrections are made the ending `-tät` becomes 100% accurate. This process presents a surprising use of *Genutiv*, in that it becomes a tool to check the gender of nouns listed on Wiktionary. Additionally, it should be noted, that *Sprachloyalität* is a compound noun that ends in the feminine noun [Loyalität](http://www.dict.cc/?s=Loyalität), which should have been filtered from the source database anyway.

## Parsing patterns ##
Many morphological patterns are only accurate when combined with semantics (see: [Morphological patterns](/blog/2011/08/16/gender#morphology)).

[^taet]: See Sozialität article from [April 12, 2011](http://de.wiktionary.org/w/index.php?title=Sozialität&oldid=1788875) and Sprachloyalität article from [April 12, 2011](http://de.wiktionary.org/w/index.php?title=Sprachloyalität&oldid=1786765).
[^Augst]: Gerhard Augst, *[Untersuchungen zum Morpheminventar der deutschen Gegenwartssprache](http://books.google.com/books?id=kukdAQAAIAAJ)* (Tübingen: Narr, 1975)
[^select]: For further information about why certain nouns were excluded see: [Noun selection](/blog/2011/08/16/gender/#select)
[^page]: Alternatively, one could check the categories assigned to every page in the _Substantiv (Deutsch)_ category and then remove undesirable nouns. Although this process should produce the same list of nouns, the process is significantly longer.

