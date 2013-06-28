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

def list_tags(fname):
    print '%s:' % fname,
    try:
        print ' ,'.join(xattr.get(fname, TAGS).split(','))
    except IOError, e:
        print

def filter_tags(fname, regex, hr):
    try:
        tags = xattr.get(fname, TAGS).split(',')
        for tag in tags:
            if regex.match(tag):
                print fname, '(' + tag + ')' if hr else ''
                break
    except IOError:
        return False

if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='Neversearch',
        version='0.01')
    parser.add_argument('file', help='', nargs='+')
    parser.add_argument('-a', '--add', type=str, help='Add a tag; can be comma'
        ' seperated (without spaces)', default=None)
    parser.add_argument('-d', '--delete', type=str, help='Delete a single tag',
        default=None)
    parser.add_argument('-C', '--clear', help='Clear all tags', action='store_true')
    parser.add_argument('-r', '-R', '--recursive', help='Recursively apply'
        ' operation', action='store_true')
    parser.add_argument('-l', '--list', help='List tags', action='store_true')
    parser.add_argument('-f', '--filter', help='Filter on tag (regex)',
        type=str, default=None)
    parser.add_argument('-H', '--human-readable', help='Human readable; may'
        ' mess with parseability', action='store_true', dest='human')
    parser.add_argument('-i', '--ignore-case', help='Ignore casing for filter',
        action='store_true')

    a = parser.parse_args()
    files = a.file

    s = sum(map(int, map(bool, (a.add, a.delete, a.clear, a.list, a.filter))))
    if s > 1:
        print >>sys.stderr, 'Too many options.'
        parser.print_help()
        exit(1)
    if s == 0:
        print >>sys.stderr, 'Too few options.'
        parser.print_help()
        exit(1)

    if a.add:
        fnc = lambda name: add_tag(name, a.add)
    elif a.delete:
        fnc = lambda name: del_tag(name, a.delete)
    elif a.clear:
        fnc = clear
    elif a.list:
        fnc = list_tags
    elif a.filter:
        fnc = lambda name: filter_tags(name, re.compile(a.filter,
            re.S | (re.I if a.ignore_case else 0)), a.human)

    if a.recursive:
        for fi in files:
            if os.path.isdir(fi):
                for r, d, f in os.walk(fi):
                    rf = lambda y: os.path.join(r, y)
                    map(fnc, map(rf, f))
                    map(fnc, map(rf, d))
            fnc(fi)
    else:
        map(fnc, files)
