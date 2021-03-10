# frozen_string_literal: true

RSpec.describe(Abt::Providers::Harvest::Commands::Start, :harvest) do
  it "is a subclass of Track" do
    expect(Abt::Providers::Harvest::Commands::Start.superclass).to(
      be(Abt::Providers::Harvest::Commands::Track)
    )
  end

  it "has it's own description and usage" do
    expect(Abt::Providers::Harvest::Commands::Start.usage).not_to(
      eq(Abt::Providers::Harvest::Commands::Track.usage)
    )

    expect(Abt::Providers::Harvest::Commands::Start.description).not_to(
      eq(Abt::Providers::Harvest::Commands::Track.description)
    )
  end
end
