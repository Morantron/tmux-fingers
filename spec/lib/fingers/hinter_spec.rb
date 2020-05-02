describe Fingers::Hinter do
  let(:input) do
    'ola ke ase'
  end

  let(:width) { 80 }

  let(:state) do
    state_double = double(:state)

    allow(state_double).to_receive(:selected_hints).and_return([])
    allow(state_double).to_receive(:compact_mode).and_return(true)

    state_double
  end

  let(:output) do
    output = double(:output)
    allow(printer_double).to_receive(:print)

    output_double
  end
end
