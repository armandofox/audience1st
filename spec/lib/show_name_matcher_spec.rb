# -*- coding: utf-8 -*-
require 'rails_helper'

describe 'near-matching name of show' do
  def try_matches(list)
    list.each do |elt|
      expect(ShowNameMatcher.near_match?(elt[0], elt[1]) === elt[2]).to be_truthy
    end
  end
  specify 'ignoring case and whitespace' do
    try_matches [
      ['COMPANY', 'Company', true],
      ['Company', 'Company ', true],
      ['Les  Miserables', 'Les miserables', true]
    ]
  end
  specify 'ignoring accents' do
    try_matches [
      ['Les Misérables', 'les miserables', true]
    ]
  end
  specify 'everything matches blanks' do
    try_matches [
      ['Company', ' ', true], [nil, 'Follies', true]
    ]
  end
  specify 'ignoring leading articles' do
    try_matches [
      ['A Night to Remember', 'Night to remember, A', true],
      ['Mousetrap,The', 'The Mousetrap', true]
    ]
  end
  specify 'when different' do
    try_matches [
      ['The company', 'company', false]
    ]
  end
end
