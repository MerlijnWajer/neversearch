#!/usr/bin/env python
#encoding: utf-8

TAGS = 'user.tags'

import xattr
import sys

import os
import os.path

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

def clear(fname):
    xattr.remove(fname, TAGS)

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

    a = parser.parse_args()
    files = a.file

    s = sum(map(int, map(bool, (a.add, a.delete, a.clear))))
    if s > 1:
        print >>sys.stderr, 'Too many options.'
        parser.print_help()
        exit(1)
    if s == 0:
        print >>sys.stderr, 'Too little options.'
        parser.print_help()
        exit(1)

    if a.add:
        fnc = lambda name: add_tag(name, a.add)
    elif a.delete:
        fnc = lambda name: del_tag(name, a.delete)
    elif a.clear:
        fnc = clear


    if a.recursive:
        for fi in files:
            if os.path.isdir(fi):
                for r, d, f in os.walk(fi):
                    rf = lambda y: os.path.join(r, y)
                    map(fnc, map(rf, f))
                    map(fnc, map(rf, d))
            else:
                fnc(fi)
    else:
        map(fnc, files)
