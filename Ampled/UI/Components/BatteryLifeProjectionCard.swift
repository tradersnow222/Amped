var body: some View {
    VStack(alignment: .center, spacing: 16) {
        // Title - centered over battery
        Text("Lifespan remaining")
            .font(.headline)
            .multilineTextAlignment(.center)
        
        // Battery visualization
        verticalBatteryVisualization
            .frame(height: batteryHeight + batteryTerminalHeight + 10)
            .padding(.horizontal)
    }
} 