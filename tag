#!/usr/bin/env python
#encoding: utf-8

TAGS = 'user.tags'
import xattr, sys, os, os.path, re

def mod_tag(fname, t, op):
    if TAGS in xattr.list(fname):
        tags = xattr.get(fname, TAGS).split(',')
    else:
        tags = []
    try:
        getattr(tags, op)(t)
    except ValueError, e:
        print 'Unable to perform %s:' % op, e
    xattr.set(fname, TAGS, ','.join(set(tags)))

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

def stdin_generator(f):
    for l in f:
        yield l[:-1]
    return


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
    files = a.file

    if not files:
        files = stdin_generator(sys.stdin)

    g = lambda f, b: lambda name: f(name, b)

    fncs = [g(add_tag, _) for _ in a.add] + [g(del_tag, d) for d in a.delete] \
        + ([clear] if a.clear else []) \
        + ([g(list_tags, a.list_only)] if (a.list or a.list_only) else []) \
        + ([lambda name: filter_tags(name, re.compile(a.filter, \
            re.S | (re.I if a.ignore_case else 0)), a.human)] \
            if a.filter else [])

    if a.recursive:
        for fi in files:
            for fnc in fncs:
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
