import SwiftUI

struct ChannelsView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                Image(systemName: "tv")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("Channel Management")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Coming Soon")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Subscribe to YouTube channels and manage your video feeds here")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
            }
            .navigationTitle("Channels")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ChannelsView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelsView()
    }
}
