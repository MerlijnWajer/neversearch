#!/usr/bin/env python
#encoding: utf-8

TAGS = 'user.tags'
import xattr, sys, os, os.path, re

def mod_tag(fname, t, op):
    """
    Modify tag; either 'append' or 'remove'. (list operation)
    """
    if TAGS in xattr.list(fname):
        tags = xattr.get(fname, TAGS).split(',')
    else:
        tags = []
    try:
        getattr(tags, op)(t)
    except ValueError, e:
        print 'Unable to perform %s:' % op, e
    j = ','.join(set(tags))
    xattr.set(fname, TAGS, j)
    if j == '':
        xattr.remove(fname, TAGS)

# Create add and remove functions from mod_tag function.
add_tag = lambda fname, t: mod_tag(fname, t, 'append')
del_tag = lambda fname, t: mod_tag(fname, t, 'remove')
clear = lambda fname: xattr.remove(fname, TAGS)

def list_tags(fname, lo):
    try:
        tags = xattr.get(fname, TAGS).split(',')
        print '%s:' % fname, ', '.join(tags)
    except IOError, e:
        if not lo:
            print '%s:' % fname

def filter_tags(fname, regex, hr):
    try:
        tags = xattr.get(fname, TAGS).split(',')
        for tag in tags:
            if regex.match(tag):
                print fname + ('(' + tag + ')' if hr else '')
                break
    except IOError:
        return False


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='Neversearch',
        version='0.01')
    parser.add_argument('file', help='', nargs='*')
    parser.add_argument('-a', '--add', help='Add a tag', action='append',
        default=[])
    parser.add_argument('-d', '--delete', help='Delete a single tag',
        action='append', default=[])
    parser.add_argument('-C', '--clear', help='Clear all tags', action='store_true')
    parser.add_argument('-r', '-R', '--recursive', help='Recursively apply'
        ' operation', action='store_true')
    parser.add_argument('-l', '--list', help='List tags', action='store_true')
    parser.add_argument('-L', '--list-only', help='List only files with tags', action='store_true')
    parser.add_argument('-f', '--filter', help='Filter on tag (regex)',
        type=str, default=None)
    parser.add_argument('-H', '--human-readable', help='Human readable; may'
        ' mess with parseability', action='store_true', dest='human')
    parser.add_argument('-i', '--ignore-case', help='Ignore casing for filter',
        action='store_true')

    a = parser.parse_args()

    # The files we operate on can be either read from stdin
    # (not at once, but using a generator/iterator)
    # l[:-1] because we don't want the newline/seperator
    files = a.file if a.file else (l[:-1] for l in sys.stdin)

    # g is a helper function to apply function 'f' with tag 'b' to a file
    # passed as argument to the function g
    g = lambda f, b: lambda name: f(name, b)

    # For example:
    # [g(add_tag, t) for t in a.add)] returns a list of functions,
    # each function takes one argument: the filename. The add operation and the
    # tag to add are ``closed'' in the function. So each function contains the
    # tag to add and the operation (in this case: add)
    # Something similar works for deleting, clearing and listing tags.

    # Build list of common functions: add, delete, clear, list
    fncs = [g(add_tag, _) for _ in a.add]
    fncs += [g(del_tag, d) for d in a.delete]
    fncs += ([clear] if a.clear else [])
    fncs += ([g(list_tags, a.list_only)] if (a.list or a.list_only) else [])

    # Build a list of filter functions. Allows regexes, so we compile those
    # and bind them to the functions. Again, each function contains a regex
    # it is supposed to match on
    fncs += ([lambda name: filter_tags(name,
            re.compile(a.filter, re.S | (re.I if a.ignore_case else 0)),
            a.human)] if a.filter else [])

    # For all files ... (if -r, else just apply all functions once)
    if a.recursive:
        for fi in files:
            # Apply all functions...
            for fnc in fncs:
                # If the ``file'' is a directory, apply our function to
                # all the files (and directories) in there...
                if os.path.isdir(fi):
                    for r, d, f in os.walk(fi):
                        rf = lambda y: os.path.join(r, y)
                        map(fnc, map(rf, f))
                        map(fnc, map(rf, d))
                fnc(fi)
    else:
        for fi in files:
            for fnc in fncs:
                fnc(fi)
