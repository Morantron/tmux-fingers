require 'spec_helper'

describe Fingers::MatchFormatter do
  let(:highlight_format) { '%s' }
  let(:hint_format) { '[%s]' }
  let(:hint_position) { 'left' }
  let(:selected_hint_format) { '{%s}' }
  let(:selected_highlight_format) { '{%s}' }
  let(:compact) { false }
  let(:selected) { false }
  let(:offset) { nil }

  let(:hint) { 'a' }
  let(:highlight) { 'yolo' }

  let(:formatter) do
    described_class.new(
      highlight_format: highlight_format,
      hint_format: hint_format,
      selected_highlight_format: selected_highlight_format,
      selected_hint_format: selected_hint_format,
      hint_position: hint_position,
      compact: compact
    )
  end

  let(:result) do
    formatter.format(hint: hint, highlight: highlight, selected: selected, offset: offset)
  end

  context 'when hint position' do
    context 'is set to left' do
      let(:hint_position) { 'left' }

      it 'places the hint on the left side' do
        expect(result).to eq('[a]yolo')
      end
    end

    context 'is set to right' do
      let(:hint_position) { 'right' }

      it 'places the hint on the right side' do
        expect(result).to eq('yolo[a]')
      end
    end
  end

  context 'when compact mode is set' do
    let(:compact) { true }
    let(:hint_format) { '%s' }

    context 'and position is set to left' do
      let(:hint_position) { 'left' }

      it 'correctly places the hint inside the highlight' do
        expect(result).to eq('aolo')
      end
    end

    context 'and position is set to right' do
      let(:hint_position) { 'right' }

      it 'correctly places the hint inside the highlight' do
        expect(result).to eq('yola')
      end
    end

    # TODO: what if hint is longer than highlight? hehehe
  end

  context 'when a hint is selected' do
    let(:selected) { true }

    it 'selects the correct format' do
      expect(result).to eq('{a}{yolo}')
    end
  end

  context 'when offset is provided' do
    let(:compact) { false }
    let(:offset) { [1, 5] }
    let(:highlight) { 'yoloyoloyolo' }
    let(:hint) { 'a' }
    let(:highlight_format) { '|%s|' }

    it 'only highlights at specified offset' do
      expect(result).to eq('y[a]|oloyo|loyolo')
    end
  end
end
