# -*- coding: utf-8 -*-
#
# MongoDB documentation build configuration file, created by
# sphinx-quickstart on Mon Oct  3 09:58:40 2011.
#
# This file is execfile()d with the current directory set to its containing dir.

# All configuration values have a default; values that are commented out
# serve to show the default.

import sys, os
import datetime
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "bin")))

import mongodb_docs_meta

meta = {
    'branch': mongodb_docs_meta.get_branch(),
    'commit': mongodb_docs_meta.get_commit(),
    'manual_path': mongodb_docs_meta.get_manual_path(),
    'date': str(datetime.date.today().year),
}

# -- General configuration ----------------------------------------------------

needs_sphinx = '1.0'

extensions = ["sphinx.ext.intersphinx", "sphinx.ext.extlinks", "mongodb_domain", "additional_directives"]

templates_path = ['.templates']
source_suffix = '.txt'
master_doc = 'contents'

project = u'MongoDB Meta Driver'
copyright = u'2012-' + meta['date'] + ', 10gen, Inc.'

version = '0.1'
release = version + '-dev'

current_git_commit = meta['commit']
current_git_branch = meta['branch']

rst_epilog = ".. |branch| replace:: ``" + current_git_branch + "``" + """
.. |commit| replace:: ``""" + current_git_commit + "``" + """
.. |copy| unicode:: U+000A9
.. |hardlink| replace:: http://docs.mongodb.org/""" + current_git_branch

exclude_patterns = []
composite_pages = []
pygments_style = 'sphinx'

extlinks = {
    'manual': ('https://docs.mongodb.org/manual%s', '' ),
    'issue': ('https://jira.mongodb.org/browse/%s', '' ),
    'wiki': ('http://www.mongodb.org/display/DOCS/%s', ''),
    'api': ('http://api.mongodb.org/%s', ''),
    'source': ('https://github.com/mongodb/mongo/blob/master/%s', ''),
    'docsgithub' : ( 'http://github.com/mongodb/mongo-meta-driver/blob/' + current_git_branch + '/%s', ''),
    'hardlink' : ( 'http://docs.mongodb.org/meta-driver/' + current_git_branch + '/%s', '')
}

intersphinx_mapping = {
    'pymongo': ('http://api.mongodb.org/python/current/', None),
    'mongodb': ('http://docs.mongodb.org/manual/', None)
}

# -- Options for HTML output ---------------------------------------------------

html_theme = 'mongodb'
html_theme_path = ['themes']

html_title = project + ' Manual'

html_logo = "source/.static/logo-mongodb.png"
html_static_path = ['source/.static']

html_last_updated_fmt = '%b %d, %Y'

html_copy_source = False
html_use_smartypants = Truee
html_domain_indices = True
html_use_index = True
html_split_index = False
html_show_sourcelink = False
html_show_sphinx = True
html_show_copyright = True
htmlhelp_basename = 'MongoDBdoc'

manual_edition_path = 'http://docs.mongodb.org/meta-driver/' + current_git_branch + '/' + project + '-Manual-' + current_git_branch

html_theme_options = {
    'branch': current_git_branch,
    'pdfpath':  manual_edition_path + '.pdf',
    'epubpath':  manual_edition_path + '.epub',
    'manual_path': meta['manual_path'],
    'repo_name': "mongo-meta-driver",
    'jira_project': 'DOCS',
    'google_analytics': 'UA-7301842-8',
    'project': 'meta-driver'
}

html_sidebars = {
    '**': ['pagenav.html', 'intrasites.html'],
}


# -- Options for LaTeX output --------------------------------------------------

latex_documents = [
#   (source start file, target name, title, author, documentclass [howto/manual]),
]

latex_elements = {
    'preamble': '\DeclareUnicodeCharacter{FF04}{\$} \DeclareUnicodeCharacter{FF0E}{.} \PassOptionsToPackage{hyphens}{url}',
    'pointsize': '10pt',
    'papersize': 'letterpaper'
}

latex_use_parts = True
latex_show_pagerefs = True
latex_show_urls = False
latex_domain_indices = True

# -- Options for manual page output --------------------------------------------

man_pages = [
  # (source start file, name, description, authors, manual section),
]


# -- Options for Epub output ---------------------------------------------------

# Bibliographic Dublin Core info.
epub_title = u'MongoDB'
epub_author = u'MongoDB Documentation Project'
epub_publisher = u'MongoDB Documentation Project'
epub_copyright = u'2012-' + meta['date'] + ', 10gen Inc.'
epub_theme = 'epub_mongodb'
epub_tocdup = True
epub_tocdepth = 3
epub_language = 'en'
epub_scheme = 'url'
epub_identifier = 'http://docs.mongodb.org/' + current_git_branch
epub_exclude_files = []

epub_pre_files = []
epub_post_files = []
